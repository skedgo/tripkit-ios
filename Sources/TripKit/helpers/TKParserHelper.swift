//
//  TKParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

#if canImport(MapKit)
import CoreLocation
import MapKit
#endif

enum TKParserHelper {
  
  static func parseDate(_ object: Any?) -> Date? {
    return TKRoutingQuery<Never>.parseDate(object)
  }
  
  static func requestString(for location: TKAPI.Location, includeAddress: Bool = true) -> String {
    guard includeAddress, let address = location.address else {
      return String(format: "(%f,%f)", location.latitude, location.longitude)
    }
    
    return String(format: "(%f,%f)\"%@\"", location.latitude, location.longitude, address)
  }
  
#if canImport(MapKit)
  static func requestString(for coordinate: CLLocationCoordinate2D) -> String {
    return String(format: "(%f,%f)", coordinate.latitude, coordinate.longitude)
  }
  
  static func requestString(for annotation: MKAnnotation) -> String {
    let named = TKNamedCoordinate.namedCoordinate(for: annotation)
    guard annotation.coordinate.isValid, let address = named.address else {
      return requestString(for: annotation.coordinate)
    }
    
    return String(format: "(%f,%f)\"%@\"", named.coordinate.latitude, named.coordinate.longitude, address)
  }
  
  /// Inverse of `TKParserHelper.requestString(for:)`
  static func coordinate(forRequest string: String) -> CLLocationCoordinate2D? {
    let numberPart = string.split(separator: ")").first.map(String.init) ?? string
    let pruned = numberPart
      .replacingOccurrences(of: "(", with: "")
      .replacingOccurrences(of: ")", with: "")
    let numbers = pruned.components(separatedBy: ",")
    if numbers.count != 2 {
      return nil
    }
    
    guard
      let lat = CLLocationDegrees(numbers[0]),
      let lng = CLLocationDegrees(numbers[1])
    else { return nil }
    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
  }
#endif
  
}
