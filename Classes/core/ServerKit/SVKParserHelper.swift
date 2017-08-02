//
//  SVKParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

import Marshal

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
  public class func color(for dictionary: [AnyHashable: Any]) -> SGKColor? {
    return try? SGKColor.value(from: dictionary)
  }
  
  @objc(namedCoordinateForDictionary:)
  public class func namedCoordinate(for dictionary: [AnyHashable: Any]) -> SGKNamedCoordinate? {
    return try? SGKNamedCoordinate(object: dictionary)
  }
  
  public class func modeCoordinate(for dictionary: [AnyHashable: Any]) -> STKModeCoordinate? {
    
    if let stop = try? STKStopCoordinate(object: dictionary) {
      return stop
    } else {
      return try? STKModeCoordinate(object: dictionary)
    }
  }
  
  public class func stopCoordinate(for dictionary: [AnyHashable: Any]) -> STKStopCoordinate? {
    return try? STKStopCoordinate(object: dictionary)
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

extension SGKColor : ValueType {
  
  public static func value(from object: Any) throws -> SGKColor {
    guard
      let dict = object as? [String: CGFloat],
      let red = dict["red"] ,
      let green = dict["green"],
      let blue = dict["blue"]
      else {
        throw MarshalError.typeMismatch(expected: [String: CGFloat].self, actual: type(of: object))
    }
    
    return SGKColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
  }
  
}
