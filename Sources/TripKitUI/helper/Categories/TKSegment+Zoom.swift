//
//  TKSegment+Zoom.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import MapKit

import TripKit

extension TKSegment {
  
  func annotationsToZoomToOnMap(mode: TKUISegmentMode? = nil) -> [MKAnnotation] {
    let mode = mode ?? defaultMode
    switch mode {
    case .getReady, .book:  return annotationsForEmbarking()
    case .onSegment: return annotationsForOnService()
    }
  }
  
  private var defaultMode: TKUISegmentMode {
    if bookingQuickInternalURL != nil {
      return .book
    } else {
      return isSelfNavigating ? .onSegment : .getReady
    }
  }
  
  private func annotationsForEmbarking() -> [MKAnnotation] {
    let startSinceNow = departureTime.timeIntervalSinceNow
    if -5 * 60 < startSinceNow, startSinceNow < 15 * 60 {
      // it started between 5 mins ago and the next 15 mins
      return [start, service?.vehicle].compactMap { $0 }
    } else {
      return [start].compactMap { $0 }
    }
  }
  
  private func annotationsForOnService() -> [MKAnnotation] {
    if departureTime.timeIntervalSinceNow < 5 * 60, arrivalTime.timeIntervalSinceNow > -5 * 60 {
      // it started less than 5 mins ago and didn't arrive more than 5 mins ago
      return [start, service?.vehicle, end].compactMap { $0 }
    
    } else {
      return [start, end].compactMap { $0 }
    }
  }
  
}
