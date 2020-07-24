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
  
  @objc(requestStringForCoordinate:)
  public class func requestString(for coordinate: CLLocationCoordinate2D) -> String {
    return String(format: "(%f,%f)", coordinate.latitude, coordinate.longitude)
  }
  
  @objc(requestStringForAnnotation:)
  public class func requestString(for annotation: MKAnnotation) -> String {
    
    guard let named = TKNamedCoordinate.namedCoordinate(for: annotation), let address = named.address else {
      return requestString(for: annotation.coordinate)
    }
    
    return String(format: "(%f,%f)\"%@\"", named.coordinate.latitude, named.coordinate.longitude, address)
  }
  
  @objc(dictionaryForCoordinate:)
  public class func dictionary(for coordinate: CLLocationCoordinate2D) -> [AnyHashable: Any] {
    return [
      "lat": coordinate.latitude,
      "lng": coordinate.longitude
    ]
  }
  
  @objc(dictionaryForAnnotation:)
  public class func dictionary(for annotation: MKAnnotation) -> [AnyHashable: Any] {
    guard let named = TKNamedCoordinate.namedCoordinate(for: annotation) else {
      return dictionary(for: annotation.coordinate)
    }
    
    var dict = dictionary(for: annotation.coordinate)
    dict["name"] = named.name
    dict["address"] = named.address
    return dict
  }
  
  @objc(colorForDictionary:)
  public class func color(for dictionary: [String: Any]) -> TKColor? {
    return (try? JSONDecoder().decode(TKAPI.RGBColor.self, withJSONObject: dictionary))?.color
  }
  
  @objc(namedCoordinateForDictionary:)
  public class func namedCoordinate(for dictionary: [String: Any]) -> TKNamedCoordinate? {
    return try? JSONDecoder().decode(TKNamedCoordinate.self, withJSONObject: dictionary)
  }
  
  @objc public class func modeCoordinate(for dictionary: [String: Any]) -> TKModeCoordinate? {
    let decoder = JSONDecoder()
    if let stop = try? decoder.decode(TKStopCoordinate.self, withJSONObject: dictionary) {
      return stop
    } else {
      return try? decoder.decode(TKModeCoordinate.self, withJSONObject: dictionary)
    }
  }
  
  @objc public class func stopCoordinate(for dictionary: [String: Any]) -> TKStopCoordinate? {
    return try? JSONDecoder().decode(TKStopCoordinate.self, withJSONObject: dictionary)
  }
  
  @objc(dashPatternForModeGroup:)
  public class func dashPattern(for modeGroup: TKParserHelperMode) -> [NSNumber] {
    // walking has regular dashes; driving has longer dashes, public has full lines
    switch modeGroup {
    case .walking: return [1, 10]
    case .transit: return [10, 20]
    case .vehicle: return [1]
    }
  }

}
