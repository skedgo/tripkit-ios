//
//  TKUIModePicker+RoutingMode.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKRegion.RoutingMode: TKUIModePickerItem {
  public var imageURLIsTemplate: Bool { return remoteImageIsTemplate }
  public var imageTextRepresentation: String { return title }
}
