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
}

@available(*, unavailable, renamed: "TKUIImageAnnotationDisplayable")
public typealias STKDisplayablePoint = TKUIImageAnnotation

@available(*, unavailable, renamed: "TKUIImageAnnotationDisplayable")
public typealias TKDisplayablePoint = TKUIImageAnnotation

@available(*, unavailable, renamed: "TKUIStopAnnotation")
public typealias TKStopAnnotation = TKUIStopAnnotation

@available(*, unavailable, renamed: "TKUIStopAnnotation")
public typealias STKStopAnnotation = TKUIStopAnnotation

@available(*, unavailable, renamed: "TKUIGlyphableAnnotation")
public typealias TKGlyphableAnnotation = TKUIGlyphableAnnotation
