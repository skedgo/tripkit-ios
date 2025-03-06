//
//  TKShareHelper+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 29/08/2016.
//
//

#if canImport(CoreData)

import Foundation
import CoreData
import CoreLocation
import MapKit

// MARK: - Query URLs

public extension TKShareHelper {
  
  enum ExtractionError: String, Error {
    case invalidURL
  }
  
}

extension TKRoutingQuery {
  /// Converts the query details into a TripRequest
  /// - parameter tripKit: TripKit's managed object context into which
  ///                      to insert the request
  public func toTripRequest(in tripKit: NSManagedObjectContext = TripKit.shared.tripKitContext) -> TripRequest {
    assert(tripKit.parent != nil || Thread.isMainThread)
    
    let start, end: MKAnnotation
    if from.isValid {
      start = TKNamedCoordinate(from)
    } else {
      start = TKLocationManager.shared.currentLocation
    }
    
    if to.isValid {
      end = TKNamedCoordinate(to)
    } else {
      end = TKLocationManager.shared.currentLocation
    }
    
    let timeType: TKTimeType
    let date: Date?
    switch self.at {
    case .leaveASAP:
      timeType = .leaveASAP
      date = nil
    case .leaveAfter(let time):
      timeType = .leaveAfter
      date = time
    case .arriveBy(let time):
      timeType = .arriveBefore
      date = time
    }
    
    return TripRequest.insert(from: start, to: end, for: date, timeType: timeType, into: tripKit)
  }
}

// MARK: - Stop URLs

public extension TKShareHelper {
  
  struct StopDetails {
    public init(region: String, code: String, filter: String?) {
      self.region = region
      self.code = code
      self.filter = filter
    }
    
    public let region: String
    public let code: String
    public let filter: String?
  }

}

// MARK: - Service URLs

public extension TKShareHelper {
  
  struct ServiceDetails {
    public init(region: String, stopCode: String, serviceID: String) {
      self.region = region
      self.stopCode = stopCode
      self.serviceID = serviceID
    }
    
    public let region: String
    public let stopCode: String
    public let serviceID: String
  }

}

#endif
