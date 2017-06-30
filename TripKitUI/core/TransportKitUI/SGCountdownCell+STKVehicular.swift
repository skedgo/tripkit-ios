//
//  SGCountdownCell+STKVehicular.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension SGCountdownCell {
  
  public func configure(for vehicle: STKVehicular, includeSubtitle: Bool) {
    let icon = STKVehicularHelper.icon(forVehicle: vehicle)
    
    configure(withTitle: vehicle.title, subtitle: vehicle.subtitle, subsubtitle: nil, icon: icon, iconImageURL: nil, timeToCountdownTo: nil, parkingAvailable: nil, position: .edgeToEdge, strip: nil, alert: nil, alertIconType: STKInfoIconType.none.rawValue)
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

