//
//  TKUIResultsAccessoryView.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUIResultsAccessoryView: UIView {

  @IBOutlet var stackView: UIStackView!
  @IBOutlet weak var timeButton: UIButton!
  @IBOutlet weak var transportButton: UIButton!
  
  static func instantiate() -> TKUIResultsAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUIResultsAccessoryView", owner: nil, options: nil)!.first as? TKUIResultsAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = UIColor { traits in
      if traits.accessibilityContrast == .high {
        return UIColor.tkAppTintColor.withAlphaComponent(0.04)
      } else {
        return UIColor.tkAppTintColor.withAlphaComponent(0.12)
      }
    }
    
    let foregroundColor = UIColor { traits in
      if traits.accessibilityContrast == .high {
        return #colorLiteral(red: 0.2384867668, green: 0.442800492, blue: 0.3663875461, alpha: 1)
      } else {
        return UIColor.tkAppTintColor
      }
    }
    
    timeButton.setTitle(nil, for: .normal)
    timeButton.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    timeButton.titleLabel?.adjustsFontForContentSizeCategory = true
    timeButton.tintColor = foregroundColor
    
    transportButton.setTitle(" \(Loc.Transport)", for: .normal)
    transportButton.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    transportButton.titleLabel?.adjustsFontForContentSizeCategory = true
    transportButton.tintColor = foregroundColor

    let config = UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .small)
    timeButton.setImage(.init(systemName: "clock", withConfiguration: config), for: .normal)
    transportButton.setImage(.init(systemName: "ellipsis.circle", withConfiguration: config), for: .normal)
  }
  
  func hideTransportButton() {
    transportButton.isHidden = true
  }
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
    stackView.axis = preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
  }
  
}
