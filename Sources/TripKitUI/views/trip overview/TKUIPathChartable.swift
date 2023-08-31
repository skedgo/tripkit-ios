//
//  TKUIPathChartable.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 23/8/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import TripKit

protocol TKUIPathChartable: Hashable {
  var chartTitle: String { get }
  var chartColor: TKColor { get }
}

extension TKPathFriendliness: TKUIPathChartable {
  var chartTitle: String { title }
  var chartColor: TKColor { color }
}

extension Shape.RoadTag: TKUIPathChartable {
  var chartTitle: String { localized }
  var chartColor: TKColor { safety.color }
  
}
