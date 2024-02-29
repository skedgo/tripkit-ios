//
//  TKUIServiceCardAction.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import Combine

import TGCardViewController

/// An action that can be added to a `TKUI<*>Card`. An array of these actions
/// is typically generated by a factory method in a card's configuration property,
/// e.g., `TKUITripOverviewCard.config.tripActionsFactory` or
/// `TKUIServiceCard.config.serviceActionsFactory`
///
/// For a concerte example, see `TKUIStartTripAction`.
///
/// If the action changes the state of the button itself, some care need to be
/// taken that this is reflected:
///
/// ```swift
/// func buildFavoriteAction(stop: TKUIStopAnnotation) -> TKUITimetableCard.Action {
///   func isFavorite() -> Bool { FavoriteHelper.isFavorite(stop) }
///   func title() -> String { isFavorite() ? "Remove" : "Add" }
///   func icon() -> UIImage { isFavorite() ? UIImage.remove : UIImage.add }
///
///   return TKUITimetableCard.Action(
///     title: title, icon: icon
///   ) { action, _, stop, _ in
///     FavoriteHelper.toggleFavorite(stop)
///   }
/// }
///
/// ```
@MainActor
open class TKUICardAction<Card, Model>: ObservableObject where Card: TGCard {
  
  /// Initialises a new card action, which can be used to add custom buttons to a card that reflect some
  /// external state.
  ///
  /// - Parameters:
  ///   - content: Publisher of the content for the button
  ///   - priority: Priority of action to determine ordering in a list
  ///   - handler: Handler executed when user taps on the button. Parameters are the owning card, the model instance, and the sender.
  public init(
    content: AnyPublisher<TKUICardActionContent, Never>,
    priority: Int = 0,
    handler: @escaping @MainActor (TKUICardAction<Card, Model>, Card, Model, UIView) -> Void
  ) {
    self.handler = { action, card, model, view in
      handler(action, card, model, view)
      return true
    }
    self.content = .init(title: "", accessibilityLabel: "", icon: UIImage(), style: .normal)
    self.priority = priority
    self.cancellable = content.assign(to: \.content, on: self)
  }
  
  /// Initialises a new card action, which can be used to add custom buttons to a card.
  ///
  /// - Parameters:
  ///   - title: Action button title.
  ///   - accessibilityLabel: Accessibility label to use for the button. Uses `title` if not provided.
  ///   - icon: Icon to display as the action. Should be a template image.
  ///   - style: Style for the button.
  ///   - priority: Priority of action to determine ordering in a list
  ///   - isEnabled: Set to `false` to show the button but disable it
  ///   - handler: Handler executed when user taps on the button. Parameters are the action itself, the owning card, the model instance, and the sender. Should return whether the button should be refreshed, by calling the relevant "actions factory" again.
  public init(
    title: String,
    accessibilityLabel: String? = nil,
    icon: UIImage,
    style: TKUICardActionStyle = .normal,
    priority: Int = 0,
    isEnabled: Bool = true,
    handler: @escaping @MainActor (TKUICardAction<Card, Model>, Card, Model, UIView) -> Bool
  ) {
    self.content = .init(
      title: title,
      accessibilityLabel: accessibilityLabel,
      icon: icon,
      style: style,
      isEnabled: isEnabled
    )
    self.handler = handler
    self.priority = priority
  }
  
  /// Initialises a new card action where the properties change depending on the handler.
  ///
  /// All the closures are called when first displaying the action, and after the handler is called on every tap.
  ///
  /// - Parameters:
  ///   - title: Provider of title for button.
  ///   - accessibilityLabel: Provider of accessibility label for the button. Uses `title` if not provided.
  ///   - icon: Provider of icon for the button. Should be a template image.
  ///   - style: Provider of style for the button.
  ///   - priority: Priority of action to determine ordering in a list
  ///   - isEnabled: Set to `false` to show the button but disable it
  ///   - handler: Handler executed when user taps on the button. Parameters are the owning card, the model instance, and the sender.
  public convenience init(
    title: @escaping () -> String,
    accessibilityLabel: (() -> String)? = nil,
    icon: @escaping () -> UIImage,
    style: (() -> TKUICardActionStyle)?  = nil,
    priority: Int = 0,
    isEnabled: Bool = true,
    handler: @escaping @MainActor (Card, Model, UIView) -> Void
  ) {
    self.init(
      title: title(),
      accessibilityLabel: accessibilityLabel?(),
      icon: icon(),
      style: style?() ?? .normal,
      priority: priority,
      isEnabled: isEnabled
    ) { action, card, model, view in
      handler(card, model, view)
      action.content = .init(
        title: title(),
        accessibilityLabel: accessibilityLabel?() ?? title(),
        icon: icon(),
        style: style?() ?? .normal
      )
      return true
    }
  }
  
  @Published var content: TKUICardActionContent
  
  private var cancellable: AnyCancellable?
  
  /// Title of the button
  public var title: String {
    get { content.title }
    set { content.title = newValue }
  }
  
  /// Accessibility label to use for the button
  public var accessibilityLabel: String {
    get { content.accessibilityLabel ?? content.title }
    set { content.accessibilityLabel = newValue }
  }
  
  /// Icon to display as the action. Should be a template image.
  public var icon: UIImage {
    get { content.icon }
    set { content.icon = newValue }
  }
  
  public var style: TKUICardActionStyle {
    get { content.style }
    set { content.style = newValue }
  }
  
  public var isInProgress: Bool {
    get { content.isInProgress }
    set { content.isInProgress = newValue }
  }
  
  public var isEnabled: Bool {
    get { content.isEnabled }
    set { content.isEnabled = newValue }
  }
  
  /// Priority of the action to determine ordering in a list. Defaults to 0.
  ///
  /// If multiple actions have the same priority, then `.bold` style is
  /// preferred and otherwise by insertion order.
  public var priority: Int

  /// Handler executed when user taps on the button, providing the
  /// corresponding card and model instance. Should return whether the button
  /// should be refreshed as its title or icon changed as a result (e.g., for
  /// toggle actions such as adding or removing a reminder or favourite).
  ///
  /// Parameters are the action itself, the owning card, the model instance, and the sender.
  public let handler: @MainActor (TKUICardAction<Card, Model>, Card, Model, UIView) -> Bool
}

public struct TKUICardActionContent {
  public init(title: String, accessibilityLabel: String? = nil, icon: UIImage, style: TKUICardActionStyle = .normal, isInProgress: Bool = false,  isEnabled: Bool = true) {
    self.title = title
    self.accessibilityLabel = accessibilityLabel
    self.icon = icon
    self.style = style
    self.isInProgress = isInProgress
    self.isEnabled = isEnabled
  }
  
  /// Title of the button
  public var title: String
  
  /// Accessibility label to use for the button, falls back to `title` if not provided
  public var accessibilityLabel: String?
  
  /// Icon to display as the action. Should be a template image.
  public var icon: UIImage
  
  public var style: TKUICardActionStyle
  
  public var isInProgress: Bool
  
  public var isEnabled: Bool
}
