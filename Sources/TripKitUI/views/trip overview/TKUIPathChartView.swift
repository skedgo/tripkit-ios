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
  init?(values: [TKUIPathChartView.ChartValue], totalDistance: CLLocationDistance? = nil) {
    let longEnough = values.filter { $0.distance > 25 }
    guard !longEnough.isEmpty else { return nil }
    
    self.values = longEnough.sorted { lhs, rhs in
      switch lhs.value.chartOrderCompared(to: rhs.value) {
      case .orderedSame:
        return lhs.value.chartTitle < rhs.value.chartTitle
      case .orderedAscending:
        return true
      case .orderedDescending:
        return false
      }
    }
    
    if let total = totalDistance {
      self.totalDistance = total
    } else {
      self.totalDistance = values.map(\.distance).reduce(0, +)
    }
  }
  
  struct ChartValue: Hashable {
    var value: V
    var distance: CLLocationDistance
  }

  let values: [ChartValue]
  let totalDistance: CLLocationDistance
  
  var body: some View {
    Chart(values , id: \.value) {
      BarMark(
        x: .value("Count", $0.distance),
        y: .value("Value", $0.value.chartTitle),
        width: .fixed(5)
      )
      .foregroundStyle(Color($0.value.chartColor))
    }
    .chartXScale(domain: 0 ... totalDistance)
    .chartXAxis {
      AxisMarks(preset: .aligned, position: .bottom, values: .automatic(desiredCount: 3)) { value in
        let distance = value.as(Double.self)!
        AxisGridLine()
        if distance > 0 { // Looks weird if that says 0 feet or 0 metres
          AxisValueLabel(MKDistanceFormatter().string(fromDistance: distance))
        }
      }
    }
    .chartYAxis {
      AxisMarks(preset: .aligned, position: .automatic) { value in
        AxisValueLabel(value.as(String.self)!)
      }
    }
    .frame(height: Double(values.count + 1) * 24) // + 1 is for the legend
    .background(Color(.tkBackground))
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

