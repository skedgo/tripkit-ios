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

/// Used as namespace
public enum TKUICardActionsViewFactory {
  
  /// Creates a view that lays out the buttons described by `actions` horizontally
  ///
  /// - Parameters:
  ///   - actions: Actions to display, displayed in same order as provided
  ///   - card: Card where this view will be embedded, will be passed to each action on tap
  ///   - model: Data model that the card is presenting, will be passed to each action on tap
  ///   - container: Container view that will host this view, will be passed to each action on tap
  ///   - padding: Padding to add around this view
  ///
  /// - Returns: Returns the view, ready to be added to the container
  public static func build<C, M>(actions: [TKUICardAction<C, M>], card: C, model: M, container: UIView, padding: Edge.Set = []) -> UIView {
    
    let actionsView: UIView
    let sorted = sort(actions: actions)
    
    if #available(iOS 16.0, *) {
      actionsView = UIHostingController(
        rootView: TKUIAdaptiveCardActions(
          actions: sorted,
          info: .init(card: card, model: model, container: container),
          normalStyle: TKUICustomization.shared.cardActionNormalStyle
        )
        .padding(padding)
      ).view
      
    } else {
      actionsView = UIHostingController(
        rootView: TKUIScrollingCardActions(
          actions: sorted,
          info: .init(card: card, model: model, container: container),
          normalStyle: TKUICustomization.shared.cardActionNormalStyle
        )
        .padding(padding)
      ).view
    }
    
    actionsView.tintColor = TKColor.tkAppTintColor
    return actionsView
  }

  static func sort<C, M>(actions: [TKUICardAction<C, M>]) -> [TKUICardAction<C, M>] {
    return actions.enumerated().sorted { lhs, rhs in
      if lhs.element.priority != rhs.element.priority {
        return lhs.element.priority > rhs.element.priority
      } else {
        switch (lhs.element.style, rhs.element.style) {
        case (.bold, _):  return true
        case (_, .bold):  return false
        default:          return lhs.offset < rhs.offset
        }
      }
    }.map(\.element)
  }
}
