//
//  TKWheelchairAccessibility+UI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.02.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKWheelchairAccessibility {
  func showInUI() -> Bool {
    return self == .notAccessible
      || TKUserProfileHelper.showWheelchairInformation
  }
  
  /// Used stand-alone, typically next to `.title`
  ///
  /// This is *not* a template image
  var icon: UIImage {
    switch self {
    case .accessible:
      return TripKitUIBundle.imageNamed("icon-wheelchair-accessible")
    case .notAccessible:
      return TripKitUIBundle.imageNamed("icon-wheelchair-not-accessible")
    case .unknown:
      return TripKitUIBundle.imageNamed("icon-wheelchair-unknown")
    }
  }
  
  /// Used in trip segments view, as a miniature icon next to the vehicle
  ///
  /// This is a template image
  var miniIcon: UIImage? {
    switch self {
    case .accessible:
      return TripKitUIBundle.imageNamed("icon-wheelchair")
    
    case .notAccessible:
      return nil // Can be added at a later stage, when needed
    
    case .unknown:
      return nil
    }
  }

  var color: UIColor {
    // Same as icons
    switch self {
    case .accessible:     return #colorLiteral(red: 0, green: 0.6078431373, blue: 0.8745098039, alpha: 1)
    case .notAccessible:  return #colorLiteral(red: 0.5794443488, green: 0.5845708847, blue: 0.5800062418, alpha: 1)
    case .unknown:        return #colorLiteral(red: 0.5794443488, green: 0.5845708847, blue: 0.5800062418, alpha: 1)
    }
  }
}
