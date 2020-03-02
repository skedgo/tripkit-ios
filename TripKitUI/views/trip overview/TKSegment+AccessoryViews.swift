//
//  TKSegment+AccessoryViews.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

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
  public func buildAccessoryViews() -> [UIView] {
    
    var accessoryViews: [UIView] = []
    
    let occupancies = realTimeVehicle?.components?.map { $0.map { $0.occupancy ?? .unknown } }
    if let occupancies = occupancies, occupancies.count > 1 {
      let trainView = TKUITrainOccupancyView()
      trainView.occupancies = occupancies
      accessoryViews.append(trainView)
    }
    
    if let occupancy = realTimeVehicle?.averageOccupancy, occupancy != .unknown {
      let occupancyView = TKUIOccupancyView(with: .occupancy(occupancy))
      accessoryViews.append(occupancyView)
    }
    
    if let accessibility = wheelchairAccessibility, accessibility.showInUI() {
      let wheelchairView = TKUIOccupancyView(with: .wheelchair(accessibility))
      accessoryViews.append(wheelchairView)
    }
    
    if canShowPathFriendliness {
      let pathFriendlinessView = TKUIPathFriendlinessView.newInstance()
      pathFriendlinessView.segment = self
      accessoryViews.append(pathFriendlinessView)
    }
    
    return accessoryViews
  }
  
}
