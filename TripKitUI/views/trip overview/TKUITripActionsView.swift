//
//  TKUITripActionsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUITripActionsView: UIView {

  private weak var stack: UIStackView!
  
  // MARK: - Initialisers
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    didInit()
  }
  
  private func didInit() {
    let stack = UIStackView()
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.axis = .horizontal
    stack.alignment = .fill
    stack.distribution = .fillEqually
    stack.spacing = 8
    
    addSubview(stack)
    self.stack = stack
    
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
    ])
  }
}

// MARK: - Configuring with content

extension TKUITripActionsView {
  
  func configure(with actions: [TKUITripOverviewCardAction], for trip: Trip, card: TKUITripOverviewCard) {
    stack.arrangedSubviews.forEach(stack.removeArrangedSubview)
    stack.removeAllSubviews()
    
    for action in actions {
      let actionView = TKUICompactActionView.newInstance()
      actionView.tintColor = .tkAppTintColor
      actionView.imageView.image = action.icon
      actionView.titleLabel.text = action.title
      actionView.bold = action.style == .bold
      actionView.onTap = { [weak card, unowned actionView] sender in
        guard let card = card else { return }
        let update = action.handler(card, sender)
        if update {
          actionView.imageView.image = action.icon
          actionView.titleLabel.text = action.title
        }
      }
      stack.addArrangedSubview(actionView)
    }
  }
  
}
