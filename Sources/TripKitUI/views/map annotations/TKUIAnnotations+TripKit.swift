//
//  TKUIAnnotations+TripKit.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.01.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

// MARK: - TKModeCoordinate

// MARK: TKUIModeAnnotation

extension TKModeCoordinate: TKUIModeAnnotation {
  public var modeInfo: TKModeInfo! {
    return stopModeInfo
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

// MARK: TKUIImageAnnotation

extension Alert: TKUIImageAnnotation {
  public var image: TKImage? {
    // Only show an image, if we have a location
    guard location != nil else { return nil }
    return TKInfoIcon.image(for: infoIconType, usage: .map)
  }
}


// MARK: - StopLocation

// MARK: TKUIModeAnnotation

extension StopLocation: TKUIModeAnnotation {
  public var modeInfo: TKModeInfo! {
    return stopModeInfo
  }

  
  public var clusterIdentifier: String? {
    return stopModeInfo?.identifier ?? "StopLocation"
  }
}

// MARK: TKUIStopAnnotation

extension StopLocation: TKUIStopAnnotation {}

// MARK: - StopVisits

// MARK: TKUIModeAnnotation

extension StopVisits: TKUIModeAnnotation {
  public var modeInfo: TKModeInfo! {
    return service.findModeInfo() ?? .unknown
  }
  
  public var clusterIdentifier: String? {
    return modeInfo?.identifier ?? "StopVisits"
  }
}

// MARK: TKUISemaphoreDisplayable

extension StopVisits: TKUISemaphoreDisplayable {
  public var selectionIdentifier: String? {
    return nil
  }
  
  public var semaphoreMode: TKUISemaphoreView.Mode? {
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

// MARK: - TKUIModeAnnotation

extension TKSegment: TKUIModeAnnotation {
  public var clusterIdentifier: String? {
    return nil
  }
}

// MARK: - TKUISemaphoreDisplayable

extension TKSegment: TKUISemaphoreDisplayable {
  public var selectionIdentifier: String? {
    // Should match the definition in TripKit => Shape
    switch order {
    case .start: return "start"
    case .regular: return String(originalSegmentIncludingContinuation().templateHashCode)
    case .end: return "end"
    }
  }
  
  public var semaphoreMode: TKUISemaphoreView.Mode? {
    if let frequency = self.frequency?.intValue {
      if !isTerminal {
        return .headWithFrequency(minutes: frequency)
      } else {
        return .headOnly
      }
    } else {
      return trip.hideExactTimes ? .headOnly : .headWithTime(departureTime, timeZone, isRealTime: timesAreRealTime)
    }
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

extension TKRegion.City: TKUIImageAnnotation {
  public var image: TKImage? { return TKStyleManager.image(named: "icon-map-info-city") }
  public var imageURL: URL? { return nil }
}
