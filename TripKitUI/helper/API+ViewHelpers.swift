//
//  API+ViewHelpers.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension API.VehicleOccupancy {
  
  public func standingPeople(occupiedColor: TKColor? = nil) -> TKImage? {
    var standingCount: Int? {
      switch self {
      case .unknown: return nil
      case .empty, .manySeatsAvailable: return 0
      case .fewSeatsAvailable: return 1
      case .standingRoomOnly: return 2
      case .crushedStandingRoomOnly: return 3
      case .full, .notAcceptingPassengers: return 4
      }
    }
    
    let color = occupiedColor ?? .tkLabelPrimary
    return standingCount.map { TKUIStyleKit.imageOfOccupancyPeople(occupied: color, occupiedCount: CGFloat($0)) }
  }

}
