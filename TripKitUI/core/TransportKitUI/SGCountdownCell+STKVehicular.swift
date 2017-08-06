//
//  SGCountdownCell+STKVehicular.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension SGCountdownCell {
  
  @objc(configureForVehicle:includeSubtitle:)
  public func configure(for vehicle: STKVehicular, includeSubtitle: Bool) {
    let icon = STKVehicularHelper.icon(forVehicle: vehicle)
    
    configure(title: vehicle.title, subtitle: vehicle.subtitle, subsubtitle: nil, icon: icon, iconImageURL: nil, timeToCountdownTo: nil, parkingAvailable: nil, position: .edgeToEdge, stripColor: nil)
  }
  
}

extension STKVehicular {
  fileprivate var title: NSAttributedString {
    let title = STKVehicularHelper.title(forVehicle: self) ?? ""
    return NSAttributedString(string: title)
  }

  fileprivate var subtitle: String? {
    let wrapped = garage?()?.title ?? nil
    return wrapped
  }
  
  
}

