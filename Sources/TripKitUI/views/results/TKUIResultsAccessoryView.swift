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
  @IBOutlet var trailingConstraint: NSLayoutConstraint!
  @IBOutlet var trailingConstraintNew: NSLayoutConstraint!
  
  static func instantiate() -> TKUIResultsAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUIResultsAccessoryView", owner: nil, options: nil)!.first as? TKUIResultsAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    let backgroundColor = UIColor { traits in
      if traits.accessibilityContrast == .high {
        return UIColor.tkAppTintColor.withAlphaComponent(0.04)
      } else {
        return UIColor.tkAppTintColor.withAlphaComponent(0.12)
      }
    }
    
    if #available(iOS 15.0, *) {
      // Align buttons to leading edge
      trailingConstraint.isActive = false
      trailingConstraintNew.isActive = true

    } else {
      // Use full space for buttons
      trailingConstraint.isActive = true
      trailingConstraintNew.isActive = false
      
      self.backgroundColor = backgroundColor
    }
    
    
    style(timeButton, title: nil, systemImageName: "clock", imagePlacement: .leading)
    style(transportButton, title: Loc.Transport, systemImageName: "chevron.down", imagePlacement: .trailing)
  }
  
  private func style(_ button: UIButton, title: String? = nil, systemImageName: String, imagePlacement: NSDirectionalRectEdge, highlight: Bool = false) {
    
    let config = UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .default)
    button.setImage(.init(systemName: systemImageName, withConfiguration: config), for: .normal)
    
    let foregroundColor = UIColor { traits in
      if traits.accessibilityContrast == .high {
        return #colorLiteral(red: 0.2384867668, green: 0.442800492, blue: 0.3663875461, alpha: 1)
      } else {
        return UIColor.tkAppTintColor
      }
    }
    
    if #available(iOS 15.0, *) {
      var config = highlight ? UIButton.Configuration.borderedTinted() : UIButton.Configuration.plain()
      config.buttonSize = .mini
      config.imagePadding = 4
      config.cornerStyle = .capsule
      config.imagePlacement = imagePlacement
      config.titleTextAttributesTransformer = .init { container in
        var updated = container
        updated.font = highlight ? TKStyleManager.semiboldCustomFont(forTextStyle: .subheadline) : TKStyleManager.customFont(forTextStyle: .subheadline)
        return updated
      }
      button.configuration = config

      button.layer.borderWidth = highlight ? 0 : 0.5
      button.layer.borderColor = TKColor.tkSeparatorSubtle.cgColor
      button.layer.cornerCurve = .continuous
      
      button.tintColor = highlight ? foregroundColor : .tkLabelPrimary
      
      button.setTitle(title, for: .normal)

    } else {
      // Legacy style - Highlight not supported
      
      button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
      button.titleLabel?.adjustsFontForContentSizeCategory = true
      
      timeButton.tintColor = foregroundColor
      transportButton.tintColor = foregroundColor
      
      button.setTitle(title.map { " \($0) " }, for: .normal)
    }
  }
  
  override func layoutSubviews() {
    // We switch dynamically to vertical layout if the natural size doesn't
    // fit horizontally OR if the time button is taller than wide.
    let timeSize = timeButton.intrinsicContentSize
    let transportSize = transportButton.intrinsicContentSize
    let fits = timeSize.width + transportSize.width + 32 < frame.width
            && timeSize.height < timeSize.width * 1.1
    stackView.axis = fits ? .horizontal : .vertical
    
    super.layoutSubviews()
    
    timeButton.layer.cornerRadius = timeButton.frame.height / 2
    transportButton.layer.cornerRadius = transportButton.frame.height / 2
  }
  
  func setTimeLabel(_ text: String, highlight: Bool) {
    style(timeButton, title: text, systemImageName: "clock", imagePlacement: .leading, highlight: highlight)
  }
  
  func setTransport(isOpen: Bool) {
    style(transportButton, title: Loc.Transport, systemImageName: isOpen ? "chevron.up" : "chevron.down", imagePlacement: .trailing)
  }
  
  func hideTransportButton() {
    transportButton.isHidden = true
  }
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
//    stackView.axis = preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
  }
  
}
