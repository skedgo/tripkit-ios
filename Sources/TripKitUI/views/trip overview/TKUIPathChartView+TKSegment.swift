//
//  TKUIPathChartView+TKSegment.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29/8/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI

import enum TripKit.TKPathFriendliness
import class TripKit.TKSegment
import class TripKit.Shape

@available(iOS 16.0, *)
extension TKSegment {
  
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
  
  func buildRoadTags() -> TKUIPathChartView<TripKit.Shape.RoadTag>? {
    guard let total = distanceInMetres?.doubleValue else {
      return nil
    }
    
    var distancesByTag = [TripKit.Shape.RoadTag: Double]()
    for shape in shapes {
      if let tags = shape.roadTags, let distance = shape.metres?.doubleValue {
        for tag in tags {
          distancesByTag[tag, default: 0] += distance
        }
      }
    }
    
    return TKUIPathChartView<TripKit.Shape.RoadTag>(
      values: distancesByTag.map { .init(value: $0, distance: $1) },
      totalDistance: total
    )
  }
  
  
}
