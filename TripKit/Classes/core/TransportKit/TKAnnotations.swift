//
//  TKAnnotations.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

import CoreLocation
import MapKit

public protocol TKGlyphableAnnotation: MKAnnotation {

  var glyphColor: TKColor? { get }
  var glyphImage: TKImage? { get }
  var glyphImageURL: URL? { get }
  var glyphImageIsTemplate: Bool { get }
  
}

@objc
public protocol TKDisplayablePoint: MKAnnotation {
  
  var pointDisplaysImage: Bool { get }
  var isDraggable: Bool { get }
  
  var pointImage: TKImage? { get }
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
public protocol TKDisplayableTimePoint: TKDisplayablePoint {
  
  var time: Date { get }
  var timeZone: TimeZone { get }
  var timeIsRealTime: Bool { get }
  var bearing: NSNumber? { get }
  var canFlipImage: Bool { get }
  var isTerminal: Bool { get }
  
}

extension TKDisplayableTimePoint {

  var timeIsRealTime: Bool { return false }
  var bearing: NSNumber? { return nil }
  var canFlipImage: Bool { return false }
  var isTerminal: Bool { return false }

}

@objc
public protocol TKModeAnnotation: TKDisplayablePoint {
  
  var stopModeInfo: TKModeInfo! { get }
  
}

@objc
public protocol TKStopAnnotation: TKModeAnnotation {
  
  var stopCode: String { get }
  
}

@available(*, unavailable, renamed: "TKDisplayablePoint")
public typealias STKDisplayablePoint = TKDisplayablePoint

@available(*, unavailable, renamed: "TKDisplayableTimePoint")
public typealias STKDisplayableTimePoint = TKDisplayableTimePoint

@available(*, unavailable, renamed: "TKModeAnnotation")
public typealias STKModeAnnotation = TKModeAnnotation

@available(*, unavailable, renamed: "TKStopAnnotation")
public typealias STKStopAnnotation = TKStopAnnotation

