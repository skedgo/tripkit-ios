//
//  TKUICardActionsViewFactory.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/4/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import SwiftUI

import TGCardViewController

import TripKit

public enum TKUICardActionsViewFactory {
  
  public static func build<C, M>(actions: [TKUICardAction<C, M>], card: C, model: M, container: UIView, showSeparator: Bool = false, padding: Edge.Set = []) -> UIView {
    
    let actionsView: UIView
    
    if #available(iOS 16.0, *) {
      actionsView = UIHostingController(
        rootView: TKUIAdaptiveCardActions(
          actions: actions,
          info: .init(card: card, model: model, container: container))
        .padding(padding)
      ).view
      
    } else {
      actionsView = UIHostingController(
        rootView: TKUIScrollingCardActions(
          actions: actions,
          info: .init(card: card, model: model, container: container))
        .padding(padding)
      ).view
    }
    
    actionsView.tintColor = TKColor.tkAppTintColor
    return actionsView
  }
  
}
