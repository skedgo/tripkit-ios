//
//  TKUICardActionsView.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

class TKUICardActionsView: UIView {
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  func configure<C, M>(with actions: [TKUICardAction<C, M>], model: M, card: C) {
    subviews.forEach { $0.removeFromSuperview() }
    
    backgroundColor = .clear
    
    if actions.count > 2 || TKUICustomization.shared.forceCompactActionsLayout {
      useCompactLayout(in: card, for: actions, with: model)
    } else {
      useExtendedLayout(in: card, for: actions, with: model)
    }
  }
  
}

extension TKUICardActionsView {
  
  private func useCompactLayout<C, M>(in card: C, for actions: [TKUICardAction<C, M>], with model: M) {
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
    
    let showActionTitle = TKUICustomization.shared.showCardActionTitle
    
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
        let update = action.handler(action, card, model, sender)
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
  
  private func useExtendedLayout<C, M>(in card: C, for actions: [TKUICardAction<C, M>], with model: M) {
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
        let update = action.handler(action, card, model, sender)
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
        actionView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        actionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
        if actions.count == 1 {
          actionView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
          actionView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.75).isActive = true
        } else {
          actionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        }
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
      
      if index == actions.count - 1, actions.count > 1 {
        actionView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
      }
      
      previousActionView = actionView
    }
  }
  
}
