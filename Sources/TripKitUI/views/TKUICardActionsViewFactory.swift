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
  /// The plain actions are also handed to the card's `verticalBarActions`.
  /// While the card controller shows those in the vertical bar of an iPhone
  /// Duo, the view leaves them out, and collapses if that leaves it empty.
  ///
  /// - SeeAlso: `TKUICardAction.isPlain`
  ///
  /// - Parameters:
  ///   - actions: Actions to display, displayed in same order as provided
  ///   - card: Card where this view will be embedded, will be passed to each action on tap
  ///   - model: Data model that the card is presenting, will be passed to each action on tap
  ///   - container: Container view that will host this view, will be passed to each action on tap
  ///   - padding: Padding to add around this view
  ///
  /// - Returns: Returns the view, ready to be added to the container
  @MainActor
  public static func build<C, M>(actions: [TKUICardAction<C, M>], card: C, model: M, container: UIView, padding: Edge.Set = []) -> UIView {
    
    let sorted = sort(actions: actions)
    let binding = TKUICardVerticalBarActionsBinding(actions: sorted, card: card, model: model)
    let rowView: UIView = UIHostingController(
      rootView: TKUIVerticalBarAwareCardActions(
        actions: sorted,
        normalStyle: TKUICustomization.shared.cardActionNormalStyle,
        visibility: binding.visibility
      ) { [weak card, model, weak container] action in
        guard let card, let container else { return }
        _ = action.handler(action, card, model, container)
      }
      .padding(padding)
    ).view
    
    let actionsView = TKUICardActionsView(
      content: rowView,
      binding: binding,
      collapsesWithPlainActions: sorted.allSatisfy(\.isPlain)
    )
    actionsView.tintColor = TKColor.tkAppTintColor
    return actionsView
  }
  
  @MainActor
  public static func build<C, M>(actions: [TKUICardAction<C, M>], handler: @escaping (TKUICardAction<C, M>) -> Void) -> some View {
    TKUIAdaptiveCardActions(
      actions: sort(actions: actions),
      normalStyle: TKUICustomization.shared.cardActionNormalStyle,
      handler: handler
    )
  }

  @MainActor
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
