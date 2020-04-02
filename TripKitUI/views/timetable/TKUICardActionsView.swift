//
//  TKUICardActionsView.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

public class TKUICardActionsView: UIView {
  
  public var showActionTitleInCompactLayout: Bool?
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public func configure<C, M>(with actions: [TKUICardAction<C, M>], model: M, card: C) {
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
    let separator = UIView()
    separator.backgroundColor = .tkSeparatorSubtle
    addSubview(separator)
    
    separator.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      separator.leadingAnchor.constraint(equalTo: leadingAnchor),
      separator.bottomAnchor.constraint(equalTo: bottomAnchor),
      separator.trailingAnchor.constraint(equalTo: trailingAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5)
    ])
    
    let showActionTitle = showActionTitleInCompactLayout ?? TKUICustomization.shared.showCardActionTitle
    
    // Split the actions into chunks of three
    let actionChunks = actions.split(into: 3)
    
    // For each chunk, map out a corresponding set of action views
    let viewChunks = actionChunks.map { actions -> [TKUICompactActionView] in
      var actionViews = actions.map { TKUICompactActionView.newInstance(with: $0, card: card, model: model, showTitle: showActionTitle) }
      
      // Since these action views are distributed equally in the containing
      // stack view (to be constructed below), to keep consistent layout for
      // all stack views (or rows), we introduce spacer elements so all rows
      // have the maximum number of actions views possible.
      let spacers = (0 ..< (3 - actionViews.count)).map { _ in TKUICompactActionView.newInstance() }
      
      // We don't want these spacer elements visible and interative. We can't
      // do `isHidden = true`, because that will cause it to be removed from
      // the stack view when layout is taking place.
      spacers.forEach { $0.alpha = 0; $0.isUserInteractionEnabled = false }
      
      actionViews.append(contentsOf: spacers)
      return actionViews
    }
    
    // For each chunk of action views, map out a corresponding stack view
    let stackChunks: [UIStackView] = viewChunks.map { actionViews in
      let stack = UIStackView()
      stack.axis = .horizontal
      stack.alignment = .center
      stack.distribution = .fillEqually
      stack.spacing = 8
      actionViews.forEach(stack.addArrangedSubview)
      return stack
    }
    
    // Now put chunks of stack views inside a parent stack view.
    let encompassingStack = UIStackView()
    encompassingStack.axis = .vertical
    encompassingStack.alignment = .fill
    encompassingStack.distribution = .fill
    encompassingStack.spacing = 8
    addSubview(encompassingStack)
    
    encompassingStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        encompassingStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        encompassingStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        encompassingStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        encompassingStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
      ]
    )
    
    stackChunks.forEach(encompassingStack.addArrangedSubview)
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

// MARK: -

extension Array {
  
  func split(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
  
}

// MARK: -

extension TKUICompactActionView {
  
  static func newInstance<C, M>(with action: TKUICardAction<C, M>, card: C, model: M, showTitle: Bool = true) -> TKUICompactActionView {
    let actionView = newInstance()
    actionView.tintColor = .tkAppTintColor
    actionView.imageView.image = action.icon
    actionView.titleLabel.text = showTitle ? action.title : nil
    actionView.accessibilityLabel = action.title
    actionView.accessibilityTraits = .button
    actionView.bold = action.style == .bold
    actionView.onTap = { [weak card, unowned actionView] sender in
      guard let card = card else { return }
      let update = action.handler(action, card, model, sender)
      if update {
        actionView.imageView.image = action.icon
        actionView.titleLabel.text = showTitle ? action.title : nil
        actionView.accessibilityLabel = action.title
        actionView.bold = action.style == .bold
      }
    }
    return actionView
  }
  
}
