//
//  TKUIMapStyler.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 28.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TKUIMapSelectionStyle {
  case selected
  case deselected
  case none
}

public protocol TKUIMapStyler {
  func selectionStyle(for overlay: MKOverlay, renderer: TKUIPolylineRenderer) -> TKUIMapSelectionStyle
}
