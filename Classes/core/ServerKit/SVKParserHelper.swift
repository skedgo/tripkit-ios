//
//  SVKParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@objc
public enum SVKParserHelperMode : Int {
  case walking
  case transit
  case vehicle
}

public class SVKParserHelper: NSObject {
  
  private override init() {
  }
  
  @objc(requestStringForCoordinate:)
  public class func requestString(for coordinate: CLLocationCoordinate2D) -> String {
    return String(format: "(%f,%f)", coordinate.latitude, coordinate.longitude)
  }
  
  @objc(requestStringForAnnotation:)
  public class func requestString(for annotation: MKAnnotation) -> String {
    
    guard let named = SGKNamedCoordinate.namedCoordinate(for: annotation), let address = named.address else {
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
    guard let named = SGKNamedCoordinate.namedCoordinate(for: annotation) else {
      return dictionary(for: annotation.coordinate)
    }
    
    var dict = dictionary(for: annotation.coordinate)
    dict["name"] = named.name
    dict["address"] = named.address
    return dict
  }
  
  @objc(colorForDictionary:)
  public class func color(for dictionary: [String: Any]) -> SGKColor? {
    return (try? JSONDecoder().decode(API.RGBColor.self, withJSONObject: dictionary))?.color
  }
  
  @objc(namedCoordinateForDictionary:)
  public class func namedCoordinate(for dictionary: [String: Any]) -> SGKNamedCoordinate? {
    return try? JSONDecoder().decode(SGKNamedCoordinate.self, withJSONObject: dictionary)
  }
  
  @objc public class func modeCoordinate(for dictionary: [String: Any]) -> STKModeCoordinate? {
    let decoder = JSONDecoder()
    if let stop = try? decoder.decode(STKStopCoordinate.self, withJSONObject: dictionary) {
      return stop
    } else {
      return try? decoder.decode(STKModeCoordinate.self, withJSONObject: dictionary)
    }
  }
  
  @objc public class func stopCoordinate(for dictionary: [String: Any]) -> STKStopCoordinate? {
    return try? JSONDecoder().decode(STKStopCoordinate.self, withJSONObject: dictionary)
  }
  
  @objc(dashPatternForModeGroup:)
  public class func dashPattern(for modeGroup: SVKParserHelperMode) -> [NSNumber] {
    // walking has regular dashes; driving has longer dashes, public has full lines
    switch modeGroup {
    case .walking: return [1, 10]
    case .transit: return [10, 20]
    case .vehicle: return [1]
    }
  }

}
