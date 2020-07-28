//
//  TKSegment+TKTripSegment.swift
//  TripKit
//
//  Created by Adrian Schönig on 23.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

// MARK: - TKTripSegment

extension TKSegment: TKTripSegment {
  
  public var tripSegmentModeTitle: String? {
    return TKSegmentBuilder._tripSegmentModeTitle(of: self)
  }

  public var tripSegmentModeSubtitle: String? {
    return TKSegmentBuilder._tripSegmentModeSubtitle(of: self)
  }

  public var tripSegmentTimeZone: TimeZone? {
    return timeZone
  }
  
  public var tripSegmentModeImage: TKImage? {
    return image()
  }
  
  public var tripSegmentModeInfo: TKModeInfo? {
    return modeInfo
  }
  
  public var tripSegmentInstruction: String {
    guard let rawString = template?.miniInstruction?.instruction else { return "" }
    let mutable = NSMutableString(string: rawString)
    TKSegmentBuilder._fill(inTemplates: mutable, for: self, inTitle: true, includingTime: true, includingPlatform: true)
    return mutable as String
  }
  
  public var tripSegmentDetail: String? {
    if let rawString = template?.miniInstruction?.detail {
      let mutable = NSMutableString(string: rawString)
      TKSegmentBuilder._fill(inTemplates: mutable, for: self, inTitle: true, includingTime: true, includingPlatform: true)
      return mutable as String
    } else {
      return nil
    }
  }
  
  public var tripSegmentTimesAreRealTime: Bool {
    return timesAreRealTime
  }
  
  public var tripSegmentWheelchairAccessibility: TKWheelchairAccessibility {
    return self.wheelchairAccessibility ?? .unknown
  }
  
  public var tripSegmentFixedDepartureTime: Date? {
    if isPublicTransport {
      if let frequency = frequency?.intValue, frequency > 0 {
        return nil
      } else {
        return departureTime
      }
    } else {
      return nil
    }
  }
  
  public var tripSegmentModeColor: TKColor? {
    // These are only used in segment views. We only want to
    // colour public transport there.
    guard isPublicTransport else { return nil }
    
    // Prefer service colour over that of the mode itself.
    return service?.color ?? modeInfo?.color
  }
  
  public var tripSegmentModeImageURL: URL? {
    return imageURL(for: .listMainMode)
  }
  
  public var tripSegmentModeImageIsTemplate: Bool {
    guard let modeInfo = modeInfo else { return false }
    return modeInfo.remoteImageIsTemplate || modeInfo.identifier.map(TKRegionManager.shared.remoteImageIsTemplate) ?? false
  }
  
  public var tripSegmentModeImageIsBranding: Bool {
    return modeInfo?.remoteImageIsBranding ?? false
  }
  
  public var tripSegmentModeInfoIconType: TKInfoIconType {
    let modeAlerts = alerts
      .filter { $0.isForMode }
      .sorted { $0.alertSeverity.rawValue > $1.alertSeverity.rawValue }

    return modeAlerts.first?.infoIconType ?? .none
  }

  public var tripSegmentSubtitleIconType: TKInfoIconType {
    let nonModeAlerts = alerts
      .filter { !$0.isForMode }
      .sorted { $0.alertSeverity.rawValue > $1.alertSeverity.rawValue }

    return nonModeAlerts.first?.infoIconType ?? .none
  }

}

extension Alert {
  fileprivate var isForMode: Bool {
    if idService != nil {
      return true
    } else if location != nil {
      return false
    } else {
      return idStopCode != nil
    }
  }
}
