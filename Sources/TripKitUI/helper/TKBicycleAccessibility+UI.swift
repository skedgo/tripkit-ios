//
//  TKBicycleAccessibility+UI.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11.03.24.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TripKit

extension TKBicycleAccessibility {
  func showInUI() -> Bool {
    return self == .accessible
      && !TKSettings.modeIdentifierIsHidden("cy_bic")
      && !TKSettings.modeIdentifierIsHidden("me_mic")
  }
  
  /// Used stand-alone, typically next to `.title`
  ///
  /// This is *not* a template image
  var icon: UIImage? {
    switch self {
    case .accessible:
      return TKUIServiceCard.config.bicycleAccessibilityImage
    case .unknown:
      return nil // Just omit it
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return nil
    }
  }
  
  /// Used in trip segments view, as a miniature icon next to the vehicle
  ///
  /// This is a template image
  var miniIcon: UIImage? {
    switch self {
    case .accessible:
      return TKUIServiceCard.config.bicycleAccessibilityImageMini
    
    case .unknown:
      return nil // Can be added at a later stage, when needed
      
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return nil
    }
  }

  var color: UIColor {
    // Same as icons
    switch self {
    case .accessible:     return #colorLiteral(red: 0.137254902, green: 0.6941176471, blue: 0.368627451, alpha: 1)
    case .unknown:  return #colorLiteral(red: 0.5794443488, green: 0.5845708847, blue: 0.5800062418, alpha: 1)
    @unknown default:
      assertionFailure("Please update TripKit dependency.")
      return #colorLiteral(red: 0.5794443488, green: 0.5845708847, blue: 0.5800062418, alpha: 1)

    }
  }
}
