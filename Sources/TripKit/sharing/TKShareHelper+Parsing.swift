//
//  TKShareHelper+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 29/08/2016.
//
//

import Foundation
import CoreData
import CoreLocation
import MapKit

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
    public var startName: String? = nil
    public var end: CLLocationCoordinate2D
    public var endName: String? = nil
    public var title: String? = nil
    public var timeType: Time = .leaveASAP
    public var modes: [String] = []
    public var additional: [URLQueryItem] = []
  }
  
  /// Extracts the query details from a TripGo API-compatible deep link
  /// - parameter url: TripGo API-compatible deep link
  /// - parameter geocoder: Geocoder used for filling in missing information
  static func queryDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) -> Result<QueryDetails, Error> {
    
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { return .failure(ExtractionError.invalidURL) }
    
    // get the input from the query
    var tlat, tlng: Double?
    var name: String?
    var flat, flng: Double?
    var type: Int?
    var time: Date?
    var modes: [String] = .init()
    for item in items {
      guard let value = item.value, !value.isEmpty else { continue }
      switch item.name {
      case "tlat":  tlat = Double(value)
      case "tlng":  tlng = Double(value)
      case "tname": name = value
      case "flat":  flat = Double(value)
      case "flng":  flng = Double(value)
      case "type":  type = Int(value)
      case "time":
        guard let date = TKParserHelper.parseDate(value) else { continue }
        time = date
      case "modes", "mode":
        modes.append(value)
      default:
        continue
      }
    }
    
    func coordinate(lat: Double?, lng: Double?) -> CLLocationCoordinate2D {
      if let lat = lat, let lng = lng {
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
      } else {
        return kCLLocationCoordinate2DInvalid
      }
    }
    
    // we need a to coordinate OR a name
    let to = coordinate(lat: tlat, lng: tlng)
    guard to.isValid else {
      return .failure(ExtractionError.missingNecessaryInformation)
    }
    
    // we're good to go, construct the time and from info
    let timeType: QueryDetails.Time
    if let type = type {
      switch (type, time != nil) {
      case (1, true): timeType = .leaveAfter(time!)
      case (2, true): timeType = .arriveBy(time!)
      default:        timeType = .leaveASAP
      }
    } else {
      timeType = .leaveASAP
    }
    let from = coordinate(lat: flat, lng: flng)
    return .success(QueryDetails(
      start: from.isValid ? from : nil,
      end: to,
      title: name,
      timeType: timeType,
      modes: modes
    ))
  }
  
}

extension TKShareHelper.QueryDetails {
  /// Converts the query details into a TripRequest
  /// - parameter tripKit: TripKit's managed object context into which
  ///                      to insert the request
  public func toTripRequest(in tripKit: NSManagedObjectContext = TripKit.shared.tripKitContext) -> TripRequest {
    assert(tripKit.parent != nil || Thread.isMainThread)
    
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
