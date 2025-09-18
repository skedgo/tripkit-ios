//
//  TKUIPathChartView+TKSegment.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29/8/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI

import struct TripKitAPI.TKAPI
import enum TripKit.TKPathFriendliness
import class TripKit.TKSegment
import class TripKit.Shape

extension TKSegment {
  
  @MainActor
  func buildFriendliness() -> TKUIPathChartView<TKPathFriendliness>? {
    guard
      let total = distanceInMetres?.doubleValue,
      let friendly = distanceInMetresFriendly?.doubleValue,
      let unfriendly = distanceInMetresUnfriendly?.doubleValue,
      let dismount = distanceInMetresDismount?.doubleValue
    else { return nil }
    
    return TKUIPathChartView<TKPathFriendliness>(
      values: [
        .init(value: .friendly, distance: friendly),
        .init(value: .unfriendly, distance: unfriendly),
        .init(value: .dismount, distance: dismount),
        .init(value: .unknown, distance: total - friendly - unfriendly - dismount)
      ]
    )
  }
  
  @MainActor
  func buildRoadTags() -> TKUIPathChartView<TKAPI.RoadTag>? {
    guard let total = distanceInMetres?.doubleValue, let distanceByRoadTags else {
      return nil
    }
    return TKUIPathChartView<TKAPI.RoadTag>(
      values: distanceByRoadTags.map { .init(value: $0, distance: $1) },
      totalDistance: total
    )
  }
  
}
