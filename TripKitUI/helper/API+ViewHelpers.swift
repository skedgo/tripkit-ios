//
//  API+ViewHelpers.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

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
      }
    }
    
    let color = occupiedColor ?? .tkLabelPrimary
    return standingCount.map { TKUIStyleKit.imageOfOccupancyPeople(occupied: color, occupiedCount: CGFloat($0)) }
  }

}
