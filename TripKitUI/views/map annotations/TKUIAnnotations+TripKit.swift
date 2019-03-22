//
//  TKUIAnnotations+TripKit.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.01.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - TKModeCoordinate

// MARK: TKUIImageAnnotationDisplayable

extension TKModeCoordinate: TKUIImageAnnotationDisplayable {
  
  public var pointClusterIdentifier: String? {
    return stopModeInfo.identifier ?? "STKModeCoordinate"
  }
  
  public var pointDisplaysImage: Bool { return stopModeInfo.localImageName != nil }

  public var pointColor: TKColor? {
    return stopModeInfo.color
  }
  
  public var pointImage: TKImage? {
    return stopModeInfo.image(type: .mapIcon)
  }
  
  public var pointImageURL: URL? {
    return stopModeInfo.imageURL(type: .mapIcon)
  }
  
  public var pointImageIsTemplate: Bool {
    return stopModeInfo.remoteImageIsTemplate
  }
  
}

// MARK: TKUIGlyphableAnnotation

extension TKModeCoordinate: TKUIGlyphableAnnotation {
  
  public var glyphColor: TKColor? {
    return stopModeInfo.glyphColor
  }
  
  public var glyphImage: TKImage? {
    let image = stopModeInfo.image
    #if os(iOS) || os(tvOS)
    return image?.withRenderingMode(.alwaysTemplate)
    #else
    return image
    #endif
    
  }
  
  public var glyphImageURL: URL? {
    guard stopModeInfo.remoteImageIsTemplate else { return nil }
    return stopModeInfo.imageURL
  }
  
  public var glyphImageIsTemplate: Bool {
    return stopModeInfo.remoteImageIsTemplate
  }
  
}

// MARK: - TKStopCoordinate

// MARK: TKUIStopAnnotation

extension TKStopCoordinate: TKUIStopAnnotation {}


// MARK: - Alert

// MARK: TKUIImageAnnotationDisplayable

extension Alert: TKUIImageAnnotationDisplayable {
  
  public var pointClusterIdentifier: String? {
    return nil
  }
  
  public var pointDisplaysImage: Bool {
    return location != nil
  }
  
  public var pointColor: TKColor? {
    return nil
  }

  public var pointImage: TKImage? {
    return TKInfoIcon.image(for: infoIconType, usage: .map)
  }
  
  public var pointImageURL: URL? {
    return imageURL
  }
  
  public var pointImageIsTemplate: Bool {
    return false
  }
  
  public var isDraggable: Bool {
    return false
  }
  
}

// MARK: - StopLocation

// MARK: TKUIStopAnnotation

extension StopLocation: TKUIImageAnnotationDisplayable {
  public var isDraggable: Bool {
    return false
  }
  
  public var pointClusterIdentifier: String? {
    return stopModeInfo?.identifier ?? "StopLocation"
  }
  
  public var pointColor: TKColor? {
    return stopModeInfo?.color
  }

  public var pointDisplaysImage: Bool {
    return pointImage != nil
  }
  
  public var pointImage: TKImage? {
    return modeImage(for: .mapIcon)
  }
  
  public var pointImageURL: URL? {
    return modeImageURL(for: .mapIcon)
  }
  
  public var pointImageIsTemplate: Bool {
    return stopModeInfo?.remoteImageIsTemplate ?? false
  }
}

// MARK: TKUIStopAnnotation

extension StopLocation: TKUIStopAnnotation {}


// MARK: - StopVisits

// MARK: TKUIImageAnnotationDisplayable

extension StopVisits: TKUIImageAnnotationDisplayable {
  
  public var pointDisplaysImage: Bool {
    return true
  }
  
  public var isDraggable: Bool {
    return false
  }
  
  public var pointClusterIdentifier: String? {
    return service.modeInfo?.identifier ?? "StopVisits"
  }
  
  public var pointColor: TKColor? {
    return service.color as? TKColor
  }

  public var pointImage: TKImage? {
    return service.modeImage(for: .listMainMode)
  }
  
  public var pointImageURL: URL? {
    return service.modeImageURL(for: .listMainMode)
  }
  
  public var pointImageIsTemplate: Bool {
    return service.modeImageIsTemplate
  }
  
}

// MARK: TKUISemaphoreDisplayable

extension StopVisits: TKUISemaphoreDisplayable {
  public var semaphoreMode: TKUISemaphoreView.Mode {
    return .none
  }
  
  public var canFlipImage: Bool {
    return true
  }
  
  public var isTerminal: Bool {
    return false
  }
}

// MARK: - TKSegment

// MARK: - TKUIImageAnnotationDisplayable

extension TKSegment: TKUIImageAnnotationDisplayable {
  
  public var isDraggable: Bool {
    return false
  }
  
  public var pointClusterIdentifier: String? {
    return nil
  }
  
  public var pointDisplaysImage: Bool {
    return coordinate.isValid && hasVisibility(.onMap)
  }
  
  public var pointColor: TKColor? {
    return tripSegmentModeColor
  }

  public var pointImage: TKImage? {
    switch order {
    case .start, .end:
      return TKStyleManager.imageNamed("icon-pin")
      
    case .regular:
      return tripSegmentModeImage
    }
  }
  
  public var pointImageURL: URL? {
    return tripSegmentModeImageURL
  }
  
  public var pointImageIsTemplate: Bool {
    return tripSegmentModeImageIsTemplate
  }
  
}

// MARK: - TKUISemaphoreDisplayable

extension TKSegment: TKUISemaphoreDisplayable {
  public var semaphoreMode: TKUISemaphoreView.Mode {
    if let frequency = self.frequency?.intValue {
      if !isTerminal {
        return .headWithFrequency(minutes: frequency)
      } else {
        return .headOnly
      }
    } else {
      if let time = departureTime {
        return .headWithTime(time, timeZone, isRealTime: timesAreRealTime)
      } else {
        // A segment might lose its trip, if the trip since got updated with
        // real-time information and the segments got rebuild
        assert(trip == nil, "Segment has a trip but no time: \(self)")
        return .headOnly
      }
    }
  }
  
  public var bearing: NSNumber? {
    return template?.bearing
  }
  
  public var canFlipImage: Bool {
    // only those pointing left or right
    return isSelfNavigating || self.modeIdentifier == TKTransportModeIdentifierAutoRickshaw
  }
  
  public var isTerminal: Bool {
    return order == .end
  }
}

// MARK: - TKRegion.City

extension TKRegion.City: TKUIImageAnnotationDisplayable {
  
  public var isDraggable: Bool { return false }
  public var pointDisplaysImage: Bool { return true }
  public var pointColor: TKColor? { return nil }
  public var pointImage: TKImage? { return TKStyleManager.imageNamed("icon-map-info-city") }
  public var pointImageURL: URL? { return nil }
  public var pointImageIsTemplate: Bool { return false }
  public var pointClusterIdentifier: String? { return "TKRegion.City" }
  
}


