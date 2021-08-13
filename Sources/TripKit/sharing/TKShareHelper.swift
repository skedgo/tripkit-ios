//
//  TKShareHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation

#if SWIFT_PACKAGE
import TripKitObjc
#endif

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
  
  @objc public static func isQueryURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/go")
  }

  @objc public static func createQueryURL(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, timeType: TKTimeType, time: Date?) -> URL? {
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

  @objc public static func isMeetURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/meet")
  }
  
  @objc public static func createMeetURL(coordinate: CLLocationCoordinate2D, at time: Date) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/meet?lat=\(degrees: coordinate.latitude)&lng=\(degrees: coordinate.longitude)&at=\(Int(time.timeIntervalSince1970))"
    return URL(string: baseURL + path)
  }
  
}

// MARK: - Stop URLs

extension TKShareHelper {

  @objc public static func isStopURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/stop")
  }

  @objc public static func createStopURL(stopCode: String, inRegionNamed regionName: String, filter: String?) -> URL? {
    guard let baseURL = TKShareHelper.baseURL else { return nil }
    let path = "/stop/\(regionName)/\(escaping: stopCode)/\(escaping: filter ?? "")"
    return URL(string: baseURL + path)
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
