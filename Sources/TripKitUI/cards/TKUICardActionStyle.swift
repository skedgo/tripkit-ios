//
//  TKUICardActionStyle.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TKUICardActionStyle: Equatable {
  /// Highlights the button with the tint colour as a circular background
  case bold

  /// Highlights the button in red tint colour with a circular background
  case destructive

  /// Normal style of the button, not tinted, with a light circular border around the icon
  case normal
}
