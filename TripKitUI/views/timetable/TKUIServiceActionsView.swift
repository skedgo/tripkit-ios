//
//  TKUIServiceActionsView.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class TKUICardActionsView: UIView {
  
  func configure(with actions: [TKUICardAction], for model: Any, card: TGCard) {
    subviews.forEach { $0.removeFromSuperview() }
    
    backgroundColor = .clear
    
    if actions.count > 2 || TKUICustomization.shared.forceCompactActionsLayout {
//      useCompactLayout(for: actions, trip: trip, in: card)
    } else {
//      useExtendedLayout(for: actions, trip: trip, in: card)
    }
  }

}

// MARK: - Configuring with content

extension TKUICardActionsView {
  
  private func useCompactLayout(for actions: [TKUICardAction], model: Any, in card: TGCardViewController) {
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
  
}
