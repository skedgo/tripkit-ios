//
//  TKAPI+ViewHelpers.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TripKit

extension TKAPI.VehicleOccupancy {
  
  /// A small icon showing 4 people, where some of them are drawn in the "occupied color",
  /// depending on occupancy.
  ///
  /// - Parameter occupiedColor: Colour for occupied state, defaults to 'primary label' colour
  /// - Returns: Image or `nil` for `.unknown` occupancy
  func standingPeople(occupiedColor: TKColor? = nil) -> TKImage? {
    var standingCount: Int? {
      switch self {
      case .unknown: return nil
      case .empty, .manySeatsAvailable: return 1
      case .fewSeatsAvailable: return 2
      case .standingRoomOnly: return 3
      case .crushedStandingRoomOnly: return 3
      case .full, .notAcceptingPassengers: return 4
      @unknown default:
        assertionFailure("Please update TripKit dependency.")
        return nil
      }
    }
    
    let color = occupiedColor ?? .tkLabelPrimary
    return standingCount.map { TKUIStyleKit.imageOfOccupancyPeople(occupied: color, occupiedCount: CGFloat($0)) }
  }

}

extension TKAPI.Alert.Severity {
  
  public var textColor: UIColor {
    switch self {
    case .alert: return .tkLabelOnDark
    case .info: return .tkBackgroundNotClear
    case .warning: return .tkLabelOnLight
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return .tkBackgroundNotClear

    }
  }
  
  public var backgroundColor: UIColor {
    switch self {
    case .alert: return .tkStateError
    case .warning: return .tkStateWarning
    case .info: return .tkLabelSecondary
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return .tkLabelSecondary

    }
  }

  public var icon: UIImage {
    let fileName: String
    switch self {
    case .info, .warning:
      fileName = "icon-alert-yellow-high-res"
    case .alert:
      fileName = "icon-alert-red-high-res"
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      fileName = "icon-alert-yellow-high-res"
    }
    return TripKitUIBundle.imageNamed(fileName)
  }
  
}
