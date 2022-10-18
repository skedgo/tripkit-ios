//
//  TKShareHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

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
  
  public static func queryDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) async throws -> QueryDetails {
    
    guard
      let components = NSURLComponents(url: url, resolvingAgainstBaseURL: false),
      let items = components.queryItems
      else { throw ExtractionError.invalidURL }
    
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
        TKLog.verbose("Ignoring \(item.name)=\(value)")
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
    guard to.isValid || name != nil else {
      throw ExtractionError.missingNecessaryInformation
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
    
    // make sure we got a destination
    let named = TKNamedCoordinate(coordinate: to)
    named.address = name
    
    let valid = try await named.tk_valid(geocoder: geocoder)
    guard valid.coordinate.isValid else {
      throw ExtractionError.missingNecessaryInformation
    }
    return QueryDetails(
      start: from.isValid ? from : nil,
      end: valid.coordinate,
      title: name,
      timeType: timeType,
      modes: modes
    )
  }
  
}

//+ (void)geocodeString:(NSString *)string
//usingGeocoder:(id<SGGeocoder>)geocoder
//completion:(void(^)( TKNamedCoordinate * _Nullable coordinate))completion
//{
//  [geocoder geocodeString:string
//    nearRegion:MKMapRectWorld
//    success:
//    ^(NSString * _Nonnull query, NSArray<TKNamedCoordinate *> * _Nonnull results) {
//    #pragma unused(query)
//    dispatch_async(dispatch_get_main_queue(), ^{
//    id<MKAnnotation> annotation = [TKGeocoderHelper pickBestFromResults:results];
//    if (annotation) {
//    TKNamedCoordinate *coordinate = [TKNamedCoordinate namedCoordinateForAnnotation:annotation];
//    coordinate.name = string;
//    completion(coordinate);
//    } else {
//    completion(nil);
//    }
//    });
//    } failure:
//    ^(NSString * _Nonnull query, NSError * _Nullable error) {
//    #pragma unused(query, error)
//    completion(nil);
//    }];
//  
//}


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
  
  public static func meetingDetails(for url: URL, using geocoder: TKGeocoding = TKAppleGeocoder()) async throws -> QueryDetails {
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

  public static func createStopURL(stopCode: String, inRegionNamed regionName: String, filter: String?) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/stop/\(regionName)/\(escaping: stopCode)/\(escaping: filter ?? "")"
    return URL(string: baseURL + path)
  }
  
  public static func stopDetails(for url: URL) throws -> StopDetails {
    let pathComponents = url.path.components(separatedBy: "/")
    guard pathComponents.count >= 4 else {
      throw ExtractionError.missingNecessaryInformation
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
  
  @objc
  public static func createServiceURL(serviceID: String, atStopCode stopCode: String, inRegionNamed regionName: String) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/service/\(regionName)/\(escaping: stopCode)/\(escaping: serviceID)"
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
      throw ExtractionError.missingNecessaryInformation
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
