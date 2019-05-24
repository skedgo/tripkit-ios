//
//  TKUIDeparturesAccessoryView.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 06.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIDeparturesAccessoryView: UIView {

  @IBOutlet weak var timeButton: UIButton!
  @IBOutlet weak var favoriteButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!
  @IBOutlet weak var customActionStack: UIStackView!
  
  
  static func newInstance() -> TKUIDeparturesAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUIDeparturesAccessoryView", owner: nil, options: nil)!.first as? TKUIDeparturesAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    timeButton.setTitle(nil, for: .normal)
  }
  
  func setCustomActions<Card, Model>(_ actions: [TKUICardAction<Card, Model>]) {
    customActionStack.arrangedSubviews.forEach(customActionStack.removeArrangedSubview)
    
    let buttons = actions.map { action -> UIButton in
      let button = UIButton(type: .custom)
      button.accessibilityLabel = action.title
      button.setImage(action.icon, for: .normal)
      button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      return button
    }
    buttons.forEach(customActionStack.addArrangedSubview)
  }
  
}
