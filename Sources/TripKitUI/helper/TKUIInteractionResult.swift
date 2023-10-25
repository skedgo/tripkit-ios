//
//  TKUITriggerResult.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 25/10/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

enum TKUIInteractionResult<F, N> {
  /// Interaction was successfully processed, and will be reflected on screen. Nothing else needed to be done.
  case success

  /// Interaction was successfully processed, and user should be navigated to a new scren.
  case navigation(N)

  /// Further input required by user before finalising the action
  case followUp(F)
  
  var followUp: F? {
    switch self {
    case .followUp(let action): return action
    case .navigation, .success: return nil
    }
  }

  var next: N? {
    switch self {
    case .followUp, .success: return nil
    case .navigation(let next): return next
    }
  }
}
