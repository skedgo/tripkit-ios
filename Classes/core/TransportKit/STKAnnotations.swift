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

@objc
public protocol STKDisplayablePoint: MKAnnotation {
  
  var pointDisplaysImage: Bool { get }
  var isDraggable: Bool { get }
  
  var pointImage: SGKImage? { get }
  var pointImageURL: URL? { get }
  @objc optional func setCoordinate(coordinate: CLLocationCoordinate2D)
  
}

extension STKDisplayablePoint {
  var pointImage: SGKImage? { return nil }
  var pointImageURL: URL? { return nil }
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
  
  var stopModeInfo: ModeInfo { get }
  
}

@objc
public protocol STKStopAnnotation: STKModeAnnotation {
  
  var stopCode: String { get }
  
}
