//
//  TKUICardBarActions.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 9/10/2026.
//  Copyright © 2026 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import Combine

import TGCardViewController

/// Whether a card's action row leaves out its plain actions, as the card
/// controller shows them in a vertical bar instead.
@MainActor
final class TKUICardActionsVisibility: ObservableObject {
  init(hidesPlainActions: Bool = false) {
    self.hidesPlainActions = hidesPlainActions
  }
  
  @Published var hidesPlainActions: Bool
}

/// Hands a card's plain actions to its `barActions`, keeps those up to date as
/// the actions change, and tracks whether the card controller shows them.
///
/// - SeeAlso: `TKUICardAction.isPlain`
@MainActor
final class TKUICardBarActionsBinding<C, M> where C: TGCard {
  
  /// - Parameters:
  ///   - actions: All the actions of the row, sorted. Only the plain ones are
  ///     handed to the card.
  ///   - card: Card that the row belongs to, which is passed to the actions'
  ///     handlers and gets the bar actions
  ///   - model: Model that's passed to the actions' handlers
  ///   - visibility: Updated with whether the card shows the bar actions,
  ///     creates a new one if not provided
  init(actions: [TKUICardAction<C, M>], card: C, model: M, visibility: TKUICardActionsVisibility? = nil) {
    let visibility = visibility ?? TKUICardActionsVisibility()
    self.visibility = visibility
    
    let plain = actions.filter(\.isPlain)
    barActions = plain.map { Self.barAction(for: $0, content: $0.content, card: card, model: model) }
    card.barActions = barActions
    
    // Update the bar's button when an action changes, e.g., when toggling a
    // favourite. This fires before `content` changes, so use the new value.
    for (index, action) in plain.enumerated() {
      action.$content
        .dropFirst()
        .sink { [weak self, weak card] content in
          guard let self, let card else { return }
          barActions[index] = Self.barAction(for: action, content: content, card: card, model: model)
          card.barActions = barActions
        }
        .store(in: &cancellables)
    }
    
    visibility.hidesPlainActions = card.showsBarActions
    observation = card.observe(\.showsBarActions, options: [.new]) { [weak visibility] card, _ in
      MainActor.assumeIsolated {
        guard let visibility, visibility.hidesPlainActions != card.showsBarActions else { return }
        visibility.hidesPlainActions = card.showsBarActions
      }
    }
  }
  
  let visibility: TKUICardActionsVisibility
  private var barActions: [UIAction]
  private var cancellables = Set<AnyCancellable>()
  private var observation: NSKeyValueObservation?
  
  private static func barAction(for action: TKUICardAction<C, M>, content: TKUICardActionContent, card: C, model: M) -> UIAction {
    var attributes: UIMenuElement.Attributes = []
    if !content.isEnabled || content.isInProgress {
      attributes.insert(.disabled)
    }
    if content.style == .destructive {
      attributes.insert(.destructive)
    }
    
    return UIAction(
      title: content.accessibilityLabel ?? content.title,
      image: content.icon,
      attributes: attributes
    ) { [weak card] uiAction in
      guard let card else { return }
      _ = action.handler(action, card, model, uiAction.sender)
    }
  }
  
}

/// Hosts a card's action row, and collapses it while it has nothing to show,
/// as all its actions are plain ones and the card controller shows those in a
/// vertical bar instead.
@MainActor
final class TKUICardActionsView: UIView {
  
  /// - Parameters:
  ///   - content: The row itself, which leaves out plain actions by itself
  ///   - binding: Kept alive for as long as this view
  ///   - collapsesWithPlainActions: Whether to collapse when the plain actions
  ///     are left out, i.e., when all actions are plain ones
  init<C, M>(content: UIView, binding: TKUICardBarActionsBinding<C, M>, collapsesWithPlainActions: Bool) {
    self.binding = binding
    super.init(frame: content.frame)
    
    backgroundColor = content.backgroundColor
    content.backgroundColor = .clear
    clipsToBounds = true
    
    content.translatesAutoresizingMaskIntoConstraints = false
    addSubview(content)
    let bottom = content.bottomAnchor.constraint(equalTo: bottomAnchor)
    bottom.priority = .required - 1 // gives way to `collapseConstraint`
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: topAnchor),
      content.leadingAnchor.constraint(equalTo: leadingAnchor),
      content.trailingAnchor.constraint(equalTo: trailingAnchor),
      bottom,
    ])
    collapseConstraint = heightAnchor.constraint(equalToConstant: 0)
    
    if collapsesWithPlainActions {
      cancellable = binding.visibility.$hidesPlainActions
        .removeDuplicates()
        .sink { [weak self] in self?.setCollapsed($0) }
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private let binding: AnyObject
  private var cancellable: AnyCancellable?
  private var collapseConstraint: NSLayoutConstraint!
  
  /// Whether the row is collapsed, as it has nothing to show
  private(set) var isCollapsed = false
  
  /// Called when the row collapses or expands after it got added to a
  /// superview, for containers that size it themselves.
  var onCollapsedChange: ((Bool) -> Void)?
  
  private func setCollapsed(_ collapsed: Bool) {
    guard collapsed != isCollapsed else { return }
    isCollapsed = collapsed
    isHidden = collapsed
    collapseConstraint.isActive = collapsed
    invalidateIntrinsicContentSize()
    
    guard let superview else { return }
    
    // Table headers and footers are sized by their frames
    if let tableView = superview as? UITableView {
      frame.size.height = collapsed ? 0 : systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      if tableView.tableHeaderView === self {
        tableView.tableHeaderView = self
      } else if tableView.tableFooterView === self {
        tableView.tableFooterView = self
      }
    }
    
    onCollapsedChange?(collapsed)
  }
  
}
