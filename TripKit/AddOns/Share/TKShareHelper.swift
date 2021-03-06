//
//  TKShareHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import CoreLocation

public class TKShareHelper: NSObject {
  private override init() {
    super.init()
  }
}

// MARK: - Query URLs

//+ (void)geocodeString:(NSString *)string
//usingGeocoder:(id<SGGeocoder>)geocoder
//completion:(void(^)( SGKNamedCoordinate * _Nullable coordinate))completion
//{
//  [geocoder geocodeString:string
//    nearRegion:MKMapRectWorld
//    success:
//    ^(NSString * _Nonnull query, NSArray<SGKNamedCoordinate *> * _Nonnull results) {
//    #pragma unused(query)
//    dispatch_async(dispatch_get_main_queue(), ^{
//    id<MKAnnotation> annotation = [SGBaseGeocoder pickBestFromResults:results];
//    if (annotation) {
//    SGKNamedCoordinate *coordinate = [SGKNamedCoordinate namedCoordinateForAnnotation:annotation];
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

  @objc public static func createQueryURL(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, timeType: SGTimeType, time: Date?) -> URL {
    return createQueryURL(start: start, end: end, timeType: timeType, time: time, baseURL: "https://tripgo.com")
  }
  
  
  @objc public static func createQueryURL(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, timeType: SGTimeType, time: Date?, baseURL: String) -> URL {
    
    // TODO: use format string and truncate lat/lng after 5 decimals
    var urlString = "\(baseURL)/go?tlat=\(end.latitude)&tlng=\(end.longitude)"
    if start.isValid {
      urlString.append("&flat=\(start.latitude)&flng=\(start.longitude)")
    }
    
    if let time = time, timeType != .leaveASAP {
      urlString.append("&time=\(Int(time.timeIntervalSince1970))&type=\(timeType.rawValue)")
    }
    
    return URL(string: urlString)!
  }
  
  
}


// MARK: - Meet URLs

extension TKShareHelper {

  @objc public static func isMeetURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/meet")
  }
  
  @objc public static func createMeetURL(coordinate: CLLocationCoordinate2D, at time: Date, baseURL: String = "https://tripgo.com") -> URL {
    let urlString = "\(baseURL)/meet?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)&at=\(Int(time.timeIntervalSince1970))"
    return URL(string: urlString)!
  }
  
}

// MARK: - Stop URLs

extension TKShareHelper {

  @objc public static func isStopURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/stop")
  }

  @objc public static func createStopURL(stopCode: String, inRegionNamed regionName: String, filter: String?) -> URL {
    return createStopURL(stopCode: stopCode, inRegionNamed: regionName, filter: filter, baseURL: "https://tripgo.com")
  }
  
  @objc public static func createStopURL(stopCode: String, inRegionNamed regionName: String, filter: String?, baseURL: String) -> URL {

    let escapedCode = (stopCode as NSString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    
    let addendum: String
    if let filter = filter, let escaped = (filter as NSString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
      addendum = escaped
    } else {
      addendum = ""
    }
    
    let urlString = "\(baseURL)/stop/\(regionName)/\(escapedCode)/\(addendum)"
    return URL(string: urlString)!
  }
  
}

// MARK: - Service URLs

extension TKShareHelper {
  
  @objc
  public static func isServiceURL(_ url: URL) -> Bool {
    return url.path.hasPrefix("/service")
  }
  
  @objc
  public static func createServiceURL(serviceID: String, atStopCode stopCode: String, inRegionNamed regionName: String, baseURL: String = "https://tripgo.com") -> URL {

    let escapedID = (serviceID as NSString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
    
    let escapedCode = (stopCode as NSString).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
  
    let urlString = "\(baseURL)/service/\(regionName)/\(escapedCode)/\(escapedID)"
    return URL(string: urlString)!
  }

}
