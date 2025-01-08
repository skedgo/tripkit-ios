//
//  TKShareHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

#if canImport(CoreData)

import Foundation
import CoreLocation
import MapKit

public class TKShareHelper: NSObject {
  private override init() {
    super.init()
  }
  
  @objc
  public static var enableSharingOfURLs: Bool {
    return TKConfig.shared.shareURLDomain != nil
  }
  
  public static var baseURL: String? {
    if let domain = TKConfig.shared.shareURLDomain {
      return domain
    } else if let scheme = TKConfig.shared.appURLScheme {
      return scheme.appending("://")
    } else {
      return nil
    }
  }
}

// MARK: - Query URLs

extension TKShareHelper {
  
  /// Extracts the query details from a TripGo API-compatible deep link
  /// - parameter url: TripGo API-compatible deep link
  /// - parameter geocoder: Geocoder used for filling in missing information
  public static func queryDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) async throws -> TKRoutingQuery<Never> {
    var query = try TKRoutingQuery(url: url).orThrow(ExtractionError.invalidURL)
    if query.to.isValid {
      return query
    }
    
    // Destination is missing coordinates, geocode it.
    let named = TKNamedCoordinate(query.to)
    named.address = query.to.name
    
    let valid = try await named.tk_valid(geocoder: geocoder)
    guard valid.coordinate.isValid else {
      throw ExtractionError.invalidURL
    }
    
    query.to = .init(annotation: valid)
    query.to.name = named.address
    return query
  }
  
}

extension TKShareHelper {
  
  public static func isQueryURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/go")
  }

  public static func createQueryURL(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, timeType: TKTimeType, time: Date?) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    
    var urlString = "\(baseURL)/go?tlat=\(degrees: end.latitude)&tlng=\(degrees: end.longitude)"
    if start.isValid {
      urlString.append("&flat=\(degrees: start.latitude)&flng=\(degrees: start.longitude)")
    }
    
    if let time = time, timeType != .leaveASAP {
      urlString.append("&time=\(Int(time.timeIntervalSince1970))&type=\(timeType.rawValue)")
    }
    
    return URL(string: urlString)
  }
  
  
}

// MARK: - Meet URLs

extension TKShareHelper {

  public static func isMeetURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/meet")
  }
  
  public static func createMeetURL(coordinate: CLLocationCoordinate2D, at time: Date) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/meet?lat=\(degrees: coordinate.latitude)&lng=\(degrees: coordinate.longitude)&at=\(Int(time.timeIntervalSince1970))"
    return URL(string: baseURL + path)
  }
  
  public static func meetingDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) async throws -> TKRoutingQuery<Never> {
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { throw ExtractionError.invalidURL }
    
    var adjusted = items.compactMap { item -> URLQueryItem? in
      guard let value = item.value, !value.isEmpty else { return nil }
      switch item.name {
      case "lat":   return URLQueryItem(name: "tlat",  value: value)
      case "lng":   return URLQueryItem(name: "tlng",  value: value)
      case "at":    return URLQueryItem(name: "time",  value: value)
      case "name":  return URLQueryItem(name: "tname", value: value)
      default:      return nil
      }
    }
    
    adjusted.append(URLQueryItem(name: "type", value: "2"))
    
    components.queryItems = adjusted
    guard let newUrl = components.url else {
      assertionFailure()
      throw ExtractionError.invalidURL
    }
    
    return try await queryDetails(for: newUrl, using: geocoder)
  }
  
}

// MARK: - Stop URLs

extension TKShareHelper {

  public static func isStopURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/stop")
  }

  @available(*, deprecated, renamed: "createStopURL(stopCode:regionCode:filter:)")
  public static func createStopURL(stopCode: String, inRegionNamed regionName: String, filter: String?) -> URL? {
    createStopURL(stopCode: stopCode, regionCode: regionName, filter: filter)
  }
    
  public static func createStopURL(stopCode: String, regionCode: String, filter: String? = nil) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/stop/\(regionCode)/\(escaping: stopCode)/\(escaping: filter ?? "")"
    return URL(string: baseURL + path)
  }
  
  public static func stopDetails(for url: URL) throws -> StopDetails {
    let pathComponents = url.path.components(separatedBy: "/")
    guard pathComponents.count >= 4 else {
      throw ExtractionError.invalidURL
    }
    
    let region = pathComponents[2]
    let code = pathComponents[3]
    let filter: String? = pathComponents.count >= 5 ? pathComponents[4] : nil
    
    return StopDetails(region: region, code: code, filter: filter)
  }
  
}

// MARK: - Service URLs

extension TKShareHelper {
  
  @objc
  public static func isServiceURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/service")
  }
  
  @available(*, deprecated, renamed: "createServiceURL(serviceID:stopCode:regionCode:)")
  @objc
  public static func createServiceURL(serviceID: String, atStopCode stopCode: String, inRegionNamed regionName: String) -> URL? {
    createServiceURL(serviceID: serviceID, stopCode: stopCode, regionCode: regionName)
  }
    
  public static func createServiceURL(serviceID: String, stopCode: String, regionCode: String) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/service/\(regionCode)/\(escaping: stopCode)/\(escaping: serviceID)"
    return URL(string: baseURL + path)
  }
  
  public static func serviceDetails(for url: URL) throws -> ServiceDetails {
    let pathComponents = url.path.components(separatedBy: "/")
    if pathComponents.count >= 5 {
      let region = pathComponents[2]
      let stopCode = pathComponents[3]
      let serviceID = pathComponents[4]
      
      return ServiceDetails(region: region, stopCode: stopCode, serviceID: serviceID)
    }

    // Old way of /service?regionName=...&stopCode=...&serviceID=...
    if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
      let region = items.value(for: "regionName"),
      let stop = items.value(for: "stopCode"),
      let service = items.value(for: "serviceID") {
      
      return ServiceDetails(region: region, stopCode: stop, serviceID: service)
      
    } else {
      throw ExtractionError.invalidURL
    }
  }

}

// MARK: - Magic

fileprivate extension String.StringInterpolation {
  mutating func appendInterpolation(degrees: CLLocationDegrees) {
    let pruned = String(format: "%.5f", degrees)
    appendLiteral(pruned)
  }

  mutating func appendInterpolation(escaping text: String) {
    let escaped = (text as NSString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    appendLiteral(escaped)
  }
}

extension Array where Element == URLQueryItem {
  
  fileprivate func value(for key: String) -> String? {
    guard let item = first(where: { $0.name == key }) else { return nil }
    
    return item.value?.removingPercentEncoding
  }
  
}

extension MKAnnotation {
  
  /// - Parameter geocoder: Geocoder to use if coordinate is not valid
  /// - Returns: An annotation with a valid coordinate, which might be different from `self`!
  public func tk_valid(geocoder: TKGeocoding) async throws -> MKAnnotation {
    if coordinate.isValid {
      return self
    }
    
    let geocodable = TKNamedCoordinate.namedCoordinate(for: self)
    try await TKGeocoderHelper.geocode(geocodable, using: geocoder, near: .world)
    return geocodable
  }
  
}

#endif
