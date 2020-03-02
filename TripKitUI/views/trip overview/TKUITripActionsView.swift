//
//  TKUITripActionsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUITripActionsView: UIView {  
  
  func configure(with actions: [TKUITripOverviewCardAction], for trip: Trip, card: TKUITripOverviewCard) {
    subviews.forEach { $0.removeFromSuperview() }
    
    backgroundColor = .clear
    
    if actions.count > 2 || TKUICustomization.shared.forceCompactActionsLayout {
      useCompactLayout(for: actions, trip: trip, in: card)
    } else {
      useExtendedLayout(for: actions, trip: trip, in: card)
    }
  }
  
}

// MARK: - Configuring with content

extension TKUITripActionsView {
  
  private func useCompactLayout(for actions: [TKUITripOverviewCardAction], trip: Trip, in card: TKUITripOverviewCard) {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.alignment = .center
    stack.distribution = .fillEqually
    stack.spacing = 8
    addSubview(stack)
    
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
      ]
    )
    
    let showActionTitle = TKUITripOverviewCard.config.showTripActionTitle
    
    let actionViews = actions.map { action -> TKUICompactActionView in
      let actionView = TKUICompactActionView.newInstance()
      actionView.tintColor = .tkAppTintColor
      actionView.imageView.image = action.icon
      actionView.titleLabel.text = showActionTitle ? action.title : nil
      actionView.accessibilityLabel = action.title
      actionView.accessibilityTraits = .button
      actionView.bold = action.style == .bold
      actionView.onTap = { [weak card, unowned actionView] sender in
        guard let card = card else { return }
        let update = action.handler(card, sender)
        if update {
          actionView.imageView.image = action.icon
          actionView.titleLabel.text = showActionTitle ? action.title : nil
          actionView.accessibilityLabel = action.title
          actionView.bold = action.style == .bold
        }
      }
      return actionView
    }
    
    actionViews.forEach(stack.addArrangedSubview)
  }
  
  private func useExtendedLayout(for actions: [TKUITripOverviewCardAction], trip: Trip, in card: TKUITripOverviewCard) {
    var previousActionView: UIView?
    
    for (index, action) in actions.enumerated() {
      let actionView = TKUIExtendedActionView.newInstance()
      actionView.tintColor = .tkAppTintColor
      actionView.imageView.image = action.icon
      actionView.label.text = action.title
      actionView.accessibilityLabel = action.title
      actionView.accessibilityTraits = .button
      actionView.bold = action.style == .bold
      actionView.onTap = { [weak card, unowned actionView] sender in
        guard let card = card else { return }
        let update = action.handler(card, sender)
        if update {
          actionView.imageView.image = action.icon
          actionView.label.text = action.title
          actionView.accessibilityLabel = action.title
          actionView.bold = action.style == .bold
        }
      }
      
      addSubview(actionView)
      
      actionView.translatesAutoresizingMaskIntoConstraints = false
      if index == 0 {
        actionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8).isActive = true
        actionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        actionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
      } else {
        guard let previous = previousActionView else { preconditionFailure() }
        actionView.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 8).isActive = true
        actionView.topAnchor.constraint(equalTo: previous.topAnchor).isActive = true
        actionView.bottomAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
        actionView.centerYAnchor.constraint(equalTo: previous.centerYAnchor).isActive = true
        let widthConstraint = actionView.widthAnchor.constraint(equalTo: previous.widthAnchor)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
      }
      
      if index == actions.count - 1 {
        actionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
      }
      
      previousActionView = actionView
    }
  }
  
}
