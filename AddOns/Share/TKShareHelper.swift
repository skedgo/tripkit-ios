//
//  TKShareHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

// MARK: - Query URL

extension TKShareHelper {
  
  public static func isQueryURL(_ url: URL) -> Bool {
    return url.path == "/go"
  }
  
  public static func createQueryURL(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, timeType: SGTimeType, time: Date?) -> URL {
    return createQueryURL(start: start, end: end, timeType: timeType, time: time, baseURL: "https://tripgo.me")
  }

  public static func createQueryURL(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D, timeType: SGTimeType, time: Date?, baseURL: String) -> URL {
    
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
