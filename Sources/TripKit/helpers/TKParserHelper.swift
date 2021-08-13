//
//  TKParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

/// :nodoc:
@objc
public enum TKParserHelperMode : Int {
  case walking
  case transit
  case vehicle
}

/// :nodoc:
public class TKParserHelper: NSObject {
  
  private override init() {
  }
  
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
  
  public class func requestString(for coordinate: CLLocationCoordinate2D) -> String {
    return String(format: "(%f,%f)", coordinate.latitude, coordinate.longitude)
  }
  
  public class func requestString(for annotation: MKAnnotation) -> String {
    
    let named = TKNamedCoordinate.namedCoordinate(for: annotation)
    guard annotation.coordinate.isValid, let address = named.address else {
      return requestString(for: annotation.coordinate)
    }
    
    return String(format: "(%f,%f)\"%@\"", named.coordinate.latitude, named.coordinate.longitude, address)
  }
  
  @objc(namedCoordinateForDictionary:)
  public class func namedCoordinate(for dictionary: [String: Any]) -> TKNamedCoordinate? {
    return try? JSONDecoder().decode(TKNamedCoordinate.self, withJSONObject: dictionary)
  }
  
  @objc public class func stopCoordinate(for dictionary: [String: Any]) -> TKStopCoordinate? {
    return try? JSONDecoder().decode(TKStopCoordinate.self, withJSONObject: dictionary)
  }
  
  public class func dashPattern(for modeGroup: TKParserHelperMode) -> [NSNumber] {
    // walking has regular dashes; driving has longer dashes, public has full lines
    switch modeGroup {
    case .walking: return [1, 10]
    case .transit: return [10, 20]
    case .vehicle: return [1]
    }
  }

}
