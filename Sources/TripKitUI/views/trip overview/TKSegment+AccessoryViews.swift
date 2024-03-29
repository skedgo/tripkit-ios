//
//  TKSegment+AccessoryViews.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import SwiftUI

import TripKit

extension TKSegment {
  
  /// Builds recommended accessory views to show for this segment in a detail
  /// view.
  ///
  /// These accessory views can include the following:
  /// - `TKUITrainOccupancyView`
  /// - `TKUIOccupancyView`
  /// - `TKUIPathFriendlinessView`
  ///
  /// - Returns: List of accessory view instances; can be empty
  @MainActor
  func buildAccessoryViews() -> [UIView] {
    
    var accessoryViews: [UIView] = []
    
    let occupancies = realTimeVehicle?.components?.map { $0.map { $0.occupancy ?? .unknown } }
    if let occupancies = occupancies, occupancies.count > 1 {
      let trainView = TKUITrainOccupancyView()
      trainView.occupancies = occupancies
      accessoryViews.append(trainView)
    }
    
    if let occupancy = realTimeVehicle?.averageOccupancy {
      let occupancyView = TKUIOccupancyView(with: .occupancy(occupancy.0, title: occupancy.title))
      accessoryViews.append(occupancyView)
    }
    
    if let accessibility = wheelchairAccessibility, accessibility.showInUI() {
      let wheelchairView = TKUIOccupancyView(with: .wheelchair(accessibility))
      accessoryViews.append(wheelchairView)
    }
    
    if let accessibility = bicycleAccessibility, accessibility.showInUI() {
      let wheelchairView = TKUIOccupancyView(with: .bicycle(accessibility))
      accessoryViews.append(wheelchairView)
    }
    
    if canShowPathFriendliness {
      if #available(iOS 16.0, *), let chart = self.buildFriendliness() {
        let host = UIHostingController(rootView: chart)
        accessoryViews.append(host.view)
      } else {
        let pathFriendlinessView = TKUIPathFriendlinessView.newInstance()
        pathFriendlinessView.segment = self
        accessoryViews.append(pathFriendlinessView)
      }
    }
    
    return accessoryViews
  }
  
}
