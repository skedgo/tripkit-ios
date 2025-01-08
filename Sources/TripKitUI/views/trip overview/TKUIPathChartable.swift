//
//  TKUIPathChartable.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 23/8/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import TripKit
import Foundation

protocol TKUIPathChartable: Hashable {
  var chartTitle: String { get }
  var chartColor: TKColor { get }
  
  
  /// If `.orderedSame` the chart value will be used, e.g., the distance
  func chartOrderCompared(to other: Self) -> ComparisonResult
}

extension TKPathFriendliness: TKUIPathChartable {
  public static func < (lhs: TKPathFriendliness, rhs: TKPathFriendliness) -> Bool {
    return false
  }
  
  var chartTitle: String { title }
  var chartColor: TKColor { color }
  
  func chartOrderCompared(to other: TKPathFriendliness) -> ComparisonResult {
    return .orderedSame
  }
}

extension TKAPI.RoadTag: TKUIPathChartable {
  var chartTitle: String { localized }
  var chartColor: TKColor { safety.color }
  
  func chartOrderCompared(to other: TKAPI.RoadTag) -> ComparisonResult {
    if safety == other.safety {
      return .orderedSame
    } else if safety < other.safety {
      return .orderedAscending
    } else {
      return .orderedDescending
    }
  }
}
