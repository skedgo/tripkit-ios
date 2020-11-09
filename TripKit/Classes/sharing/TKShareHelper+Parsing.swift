//
//  TKShareHelper+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 29/08/2016.
//
//

import Foundation

// MARK: - Query URLs

public extension TKShareHelper {
  
  enum ExtractionError: String, Error {
    case invalidURL
    case invalidCoordinate
    case missingNecessaryInformation
  }

  struct QueryDetails {
    public init(start: CLLocationCoordinate2D? = nil, end: CLLocationCoordinate2D, title: String? = nil, timeType: TKShareHelper.QueryDetails.Time = .leaveASAP, modes: [String] = [], additional: [URLQueryItem] = []) {
      self.start = start
      self.end = end
      self.title = title
      self.timeType = timeType
      self.modes = modes
      self.additional = additional
    }
    
    public static let empty = QueryDetails(end: .invalid)
    
    public enum Time: Equatable {
      case leaveASAP
      case leaveAfter(Date)
      case arriveBy(Date)
    }
    
    public var start: CLLocationCoordinate2D? = nil
    public var end: CLLocationCoordinate2D
    public var title: String? = nil
    public var timeType: Time = .leaveASAP
    public var modes: [String] = []
    public var additional: [URLQueryItem] = []
  }
  
}

extension TKShareHelper.QueryDetails {
  /// Converts the query details into a TripRequest
  /// - parameter tripKit: TripKit's managed object context into which
  ///                      to insert the request
  public func toTripRequest(in tripKit: NSManagedObjectContext = TripKit.shared.tripKitContext) -> TripRequest {
    let from, to: MKAnnotation
    if let start = start, start.isValid {
      from = TKNamedCoordinate(coordinate: start)
    } else {
      from = TKLocationManager.shared.currentLocation
    }
    
    if end.isValid {
      let named = TKNamedCoordinate(coordinate: end)
      named.name = self.title
      to = named
    } else {
      to = TKLocationManager.shared.currentLocation
    }
    
    let timeType: TKTimeType
    let date: Date?
    switch self.timeType {
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
    
    return TripRequest.insert(from: from, to: to, for: date, timeType: timeType, into: tripKit)
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
