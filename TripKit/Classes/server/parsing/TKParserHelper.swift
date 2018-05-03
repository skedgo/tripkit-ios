//
//  TKParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

extension TKParserHelper {

  @objc
  public static func parseDate(_ object: Any?) -> Date? {
    if let string = object as? String {
      if let interval = TimeInterval(string), interval > 1000000000, interval < 2000000000 {
        return Date(timeIntervalSince1970: interval)
      }
      return try? Date(iso8601: string)
      
    } else if let interval = object as? TimeInterval, interval > 0 {
      return Date(timeIntervalSince1970: interval)
      
    } else {
      return nil
    }
  }
  
}
