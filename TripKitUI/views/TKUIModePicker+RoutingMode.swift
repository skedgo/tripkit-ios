//
//  TKUIModePicker+RoutingMode.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKRegion.RoutingMode: TKUIModePickerItem {
  
  public var imageTextRepresentation: String {
    return title
  }
  
}
