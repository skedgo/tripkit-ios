//
//  TKUIAnnotations+TripKit.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.01.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

// MARK: - Protocols for TKModeCoordinate

// MARK: TKUIModeAnnotation

extension TKModeCoordinate: TKUIModeAnnotation {
  public var modeInfo: TKModeInfo? {
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
#if canImport(UIKit)
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


// MARK: - Protocols for TKStopCoordinate

// MARK: TKUIStopAnnotation

extension TKStopCoordinate: TKUIStopAnnotation {}


// MARK: - Protocols for Alert

// MARK: TKUIImageAnnotation

extension Alert: TKUIImageAnnotation {
  public var image: TKImage? {
    // Only show an image, if we have a location
    guard location != nil else { return nil }
    return TKInfoIcon.image(for: infoIconType, usage: .map)
  }
}


// MARK: - Protocols for StopLocation

// MARK: TKUIModeAnnotation

extension StopLocation: TKUIModeAnnotation {
  public var modeInfo: TKModeInfo? {
    return stopModeInfo
  }

  
  public var clusterIdentifier: String? {
    return stopModeInfo?.identifier ?? "StopLocation"
  }
}

// MARK: TKUIStopAnnotation

extension StopLocation: TKUIStopAnnotation {}

// MARK: - Protocols for StopVisits

// MARK: TKUIModeAnnotation

extension StopVisits: TKUIModeAnnotation {
  public var modeInfo: TKModeInfo? {
    return service.findModeInfo() ?? .unknown
  }
  
  public var clusterIdentifier: String? {
    return modeInfo?.identifier ?? "StopVisits"
  }
}


// MARK: - Protocols for TKSegment

// MARK: TKUIModeAnnotation

extension TKSegment: TKUIModeAnnotation {
  public var clusterIdentifier: String? {
    return nil
  }
  
  public var image: TKImage? {
    switch order {
    case .start: return nil
    case .end: return .iconPin
    case .regular: return tripSegmentModeImage
    }
  }
}

// MARK: TKUISemaphoreDisplayable

extension TKSegment: TKUISemaphoreDisplayable {
  public var selectionIdentifier: String? {
    // Should match the definition in TripKit => Shape+CoreDataClass
    switch order {
    case .start: return "start"
    case .regular: return String(originalSegmentIncludingContinuation().templateHashCode)
    case .end: return "end"
    }
  }
  
  func semaphoreMode(atStart: Bool) -> TKUISemaphoreView.Mode {
    if let frequency = self.frequency?.intValue {
      if !isTerminal, atStart {
        return .headWithFrequency(minutes: frequency)
      } else {
        return .headOnly
      }
      
    } else if !trip.hideExactTimes, self.tripSegmentFixedDepartureTime != nil {
      return .headWithTime(atStart ? departureTime : arrivalTime, timeZone, isRealTime: timesAreRealTime)
      
    } else {
      return .headOnly
    }
  }
  
  public var semaphoreMode: TKUISemaphoreView.Mode {
    semaphoreMode(atStart: true)
  }
  
  public var canFlipImage: Bool {
    // only those pointing left or right
    return isSelfNavigating
  }
  
  public var isTerminal: Bool {
    return order == .end
  }
}

// MARK: - Protocols for TKRegion.City

// MARK: TKUIImageAnnotation

extension TKRegion.City: TKUIImageAnnotation {
  public var image: TKImage? { return TKStyleManager.image(named: "icon-map-info-city") }
  public var imageURL: URL? { return nil }
}
