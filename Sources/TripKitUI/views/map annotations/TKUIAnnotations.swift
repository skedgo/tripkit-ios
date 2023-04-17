//
//  TKUIImageAnnotationDisplayable.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.01.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import CoreLocation
import MapKit

import TripKit


/// For displaying an annotation in a `MKMarkerAnnotationView`
public protocol TKUIGlyphableAnnotation: MKAnnotation {
  var glyphColor: TKColor? { get }
  var glyphImage: TKImage? { get }
  var glyphImageURL: URL? { get }
  var glyphImageIsTemplate: Bool { get }
}

/// For displaying an annotation in a `TKUIImageAnnotationView`
public protocol TKUIImageAnnotation: MKAnnotation {
  var image: TKImage? { get }
  var imageURL: URL? { get }
}

public enum TKUISelectionCondition {
  case onlyIfSomethingElseIsSelected
  case onlyIfSelected
  case ifSelectedOrNoSelection
}

public protocol TKUISelectableOnMap {
  /// Determines whether this should be shown on the map, when something is selected on the map.
  /// If the map has a selection identifier and it matches this value, then this will be displayed.
  ///
  /// If this has returns a non-nil value, it works in tandem with `selectionCondition`
  var selectionIdentifier: String? { get }
  
  /// When to show this; only has an impact if `selectionIdentifier` returns non-nil
  var selectionCondition: TKUISelectionCondition { get }
}

/// For displaying an annotation in a `TKUIModeAnnotationView`
@objc
public protocol TKUIModeAnnotation: MKAnnotation {
  var modeInfo: TKModeInfo! { get }
  var clusterIdentifier: String? { get }
}

public extension TKUIModeAnnotation {
  var image: TKImage? { return modeInfo?.image }
  var imageURL: URL? { return modeInfo?.imageURL }
  var imageIsTemplate: Bool { return modeInfo?.remoteImageIsTemplate ?? false }
}

@objc
public protocol TKUIStopAnnotation: TKUIModeAnnotation {
  var stopCode: String { get }
  var timeZone: TimeZone? { get }
}

@available(*, unavailable, renamed: "TKUIImageAnnotation")
public typealias STKDisplayablePoint = TKUIImageAnnotation

@available(*, unavailable, renamed: "TKUIImageAnnotation")
public typealias TKDisplayablePoint = TKUIImageAnnotation

@available(*, unavailable, renamed: "TKUIStopAnnotation")
public typealias TKStopAnnotation = TKUIStopAnnotation

@available(*, unavailable, renamed: "TKUIStopAnnotation")
public typealias STKStopAnnotation = TKUIStopAnnotation

@available(*, unavailable, renamed: "TKUIGlyphableAnnotation")
public typealias TKGlyphableAnnotation = TKUIGlyphableAnnotation
