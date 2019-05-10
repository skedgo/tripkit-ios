//
//  TKUIImageAnnotationDisplayable.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.01.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import CoreLocation
import MapKit

public protocol TKUIGlyphableAnnotation: MKAnnotation {
  
  var glyphColor: TKColor? { get }
  var glyphImage: TKImage? { get }
  var glyphImageURL: URL? { get }
  var glyphImageIsTemplate: Bool { get }
  
}

@objc
//@available(*, deprecated, message: "Please use use-case specific annotations instead")
public protocol TKUIImageAnnotationDisplayable: MKAnnotation {
  
  var pointDisplaysImage: Bool { get }
  var isDraggable: Bool { get }
  
  var pointColor: TKColor? { get }
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
public protocol TKUIModeAnnotation: MKAnnotation {
  var modeInfo: TKModeInfo! { get }
  var clusterIdentifier: String? { get }
}


@objc
//@available(*, deprecated, message: "Please use use-case specific annotations instead")
public protocol TKUIStopAnnotation: TKUIImageAnnotationDisplayable {
  
  var stopModeInfo: TKModeInfo! { get }
  var stopCode: String { get }
  
}

@available(*, unavailable, renamed: "TKUIImageAnnotationDisplayable")
public typealias STKDisplayablePoint = TKUIImageAnnotationDisplayable

@available(*, unavailable, renamed: "TKUIImageAnnotationDisplayable")
public typealias TKDisplayablePoint = TKUIImageAnnotationDisplayable

@available(*, unavailable, renamed: "TKUIStopAnnotation")
public typealias TKStopAnnotation = TKUIStopAnnotation

@available(*, unavailable, renamed: "TKUIStopAnnotation")
public typealias STKStopAnnotation = TKUIStopAnnotation

@available(*, unavailable, renamed: "TKUIGlyphableAnnotation")
public typealias TKGlyphableAnnotation = TKUIGlyphableAnnotation
