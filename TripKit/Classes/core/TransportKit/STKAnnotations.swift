//
//  STKStopAnnotation.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

import CoreLocation
import MapKit

public protocol TKGlyphableAnnotation: MKAnnotation {

  var glyphColor: SGKColor? { get }
  var glyphImage: SGKImage? { get }
  var glyphImageURL: URL? { get }
  var glyphImageIsTemplate: Bool { get }
  
}

@objc
public protocol STKDisplayablePoint: MKAnnotation {
  
  var pointDisplaysImage: Bool { get }
  var isDraggable: Bool { get }
  
  var pointImage: SGKImage? { get }
  var pointImageURL: URL? { get }
  var pointImageIsTemplate: Bool { get }
  
  /// Identifier for this point for clustering on a map. Typical use
  /// is to cluster nearby annotations with same identifier.
  ///
  /// Return `nil` to not allow clustering this annotation.
  var pointClusterIdentifier: String? { get }
  
  @objc optional func setCoordinate(coordinate: CLLocationCoordinate2D)
  
}

@objc
public protocol STKDisplayableTimePoint: STKDisplayablePoint {
  
  var time: Date { get }
  var timeZone: TimeZone { get }
  var timeIsRealTime: Bool { get }
  var bearing: NSNumber? { get }
  var canFlipImage: Bool { get }
  var isTerminal: Bool { get }
  
}

extension STKDisplayableTimePoint {

  var timeIsRealTime: Bool { return false }
  var bearing: NSNumber? { return nil }
  var canFlipImage: Bool { return false }
  var isTerminal: Bool { return false }

}

@objc
public protocol STKModeAnnotation: STKDisplayablePoint {
  
  var stopModeInfo: ModeInfo! { get }
  
}

@objc
public protocol STKStopAnnotation: STKModeAnnotation {
  
  var stopCode: String { get }
  
}
