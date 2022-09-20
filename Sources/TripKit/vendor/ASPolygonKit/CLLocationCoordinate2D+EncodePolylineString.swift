//
//  CLLocationCoordinate2D+EncodePolylineString.swift
//
//
//  Created by Adrian Schönig on 5/11/21.
//

import Foundation

extension Polygon {
  /// This function encodes an `Polygon` to a `String`
  ///
  /// - parameter precision: The precision used to encode coordinates (default: `1e5`)
  ///
  /// - returns: A `String` representing the encoded Polyline
  func encodeCoordinates(precision: Double = 1e5) -> String {
    
    var previousCoordinate = IntegerCoordinates(0, 0)
    var encodedPolyline = ""
    
    for coordinate in points {
      let intLatitude  = Int(round(coordinate.lat * precision))
      let intLongitude = Int(round(coordinate.lng * precision))
      
      let coordinatesDifference = (intLatitude - previousCoordinate.latitude, intLongitude - previousCoordinate.longitude)
      
      encodedPolyline += Self.encodeCoordinate(coordinatesDifference)
      
      previousCoordinate = (intLatitude,intLongitude)
    }
    
    return encodedPolyline
  }

  // MARK: - Private -
  // MARK: Encode Coordinate
  private static func encodeCoordinate(_ locationCoordinate: IntegerCoordinates) -> String {
    
    let latitudeString  = encodeSingleComponent(locationCoordinate.latitude)
    let longitudeString = encodeSingleComponent(locationCoordinate.longitude)
    
    return latitudeString + longitudeString
  }

  private static func encodeSingleComponent(_ value: Int) -> String {
    
    var intValue = value
    
    if intValue < 0 {
      intValue = intValue << 1
      intValue = ~intValue
    } else {
      intValue = intValue << 1
    }
    
    return encodeFiveBitComponents(intValue)
  }

  // MARK: Encode Levels
  private static func encodeLevel(_ level: UInt32) -> String {
    return encodeFiveBitComponents(Int(level))
  }

  private static func encodeFiveBitComponents(_ value: Int) -> String {
    var remainingComponents = value
    
    var fiveBitComponent = 0
    var returnString = String()
    
    repeat {
      fiveBitComponent = remainingComponents & 0x1F
      
      if remainingComponents >= 0x20 {
        fiveBitComponent |= 0x20
      }
      
      fiveBitComponent += 63
      
      let char = UnicodeScalar(fiveBitComponent)!
      returnString.append(String(char))
      remainingComponents = remainingComponents >> 5
    } while (remainingComponents != 0)
    
    return returnString
  }

  private typealias IntegerCoordinates = (latitude: Int, longitude: Int)
}
