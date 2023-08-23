//
//  TKUIPathChartView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 23/8/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI
import Charts
import MapKit

import enum TripKit.TKPathFriendliness
import class TripKit.Shape

@available(iOS 16.0, *)
struct TKUIPathChartView<V>: View where V: TKUIPathChartable & Hashable {
  init(values: [TKUIPathChartView.ChartValue<V>], totalDistance: CLLocationDistance? = nil) {
    self.values = values
    
    if let total = totalDistance {
      self.totalDistance = total
    } else {
      self.totalDistance = values.map(\.distance).reduce(0, +)
    }
  }
  
  struct ChartValue<V>: Hashable where V: TKUIPathChartable & Hashable {
    let value: V
    let distance: CLLocationDistance
  }

  let values: [ChartValue<V>]
  let totalDistance: CLLocationDistance
  
  var body: some View {
    Chart(Array(values.sorted { $0.distance > $1.distance }) , id: \.value) { // Array(values.sorted(by: \.percentage))
      BarMark(
        x: .value("Count", $0.distance),
        y: .value("Value", $0.value.chartTitle)
      )
      .foregroundStyle(Color($0.value.chartColor))
    }
    .chartXScale(domain: 0.1 ... totalDistance)
    .chartXAxis {
      AxisMarks(preset: .aligned, position: .bottom, values: .automatic(desiredCount: 2)) { value in
        let distance = value.as(Double.self)!
        AxisGridLine()
        AxisValueLabel(MKDistanceFormatter().string(fromDistance: distance))
      }
    }
    .chartYAxis {
      AxisMarks(preset: .aligned, position: .automatic) { value in
        AxisValueLabel(value.as(String.self)!)
      }
    }
  }
}

@available(iOS 16.0, *)
struct TKUIPathChartView_Previews: PreviewProvider {
  static var previews: some View {
    TKUIPathChartView(values: [
      .init(value: TKPathFriendliness.friendly, distance: 900),
      .init(value: TKPathFriendliness.unfriendly, distance: 213),
      .init(value: TKPathFriendliness.dismount, distance: 60),
    ])
    .previewLayout(.fixed(width: 260, height: 100))
    .previewDisplayName("Friendliness")

    TKUIPathChartView(values: [
      .init(value: Shape.RoadTag.cycleLane, distance: 1_000),
      .init(value: Shape.RoadTag.cycleTrack, distance: 2_000),
      .init(value: Shape.RoadTag.cycleNetwork, distance: 3_250),
      .init(value: Shape.RoadTag.sideRoad, distance: 750),
      .init(value: Shape.RoadTag.mainRoad, distance: 500),
    ], totalDistance: 5_000)
    .previewLayout(.fixed(width: 260, height: 120))
    .previewDisplayName("Tags")
  }
}

