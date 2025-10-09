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
  @IBOutlet var timeHeightConstraint: NSLayoutConstraint!
  @IBOutlet var transportHeightConstraint: NSLayoutConstraint!
  @IBOutlet var trailingConstraint: NSLayoutConstraint!
  @IBOutlet var trailingConstraintNew: NSLayoutConstraint!
  @IBOutlet var bottomConstraint: NSLayoutConstraint!
  
  static func instantiate() -> TKUIResultsAccessoryView {
    guard
      let view = Bundle.tripKitUI.loadNibNamed("TKUIResultsAccessoryView", owner: nil, options: nil)!.first as? TKUIResultsAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    // Align buttons to leading edge
    trailingConstraint.isActive = false
    trailingConstraintNew.isActive = true
    timeHeightConstraint.isActive = false
    transportHeightConstraint.isActive = false
    bottomConstraint.constant = 6
    
    style(timeButton, title: nil, systemImageName: "clock", imagePlacement: .leading)
    style(transportButton, title: Loc.Transport, systemImageName: "chevron.down", imagePlacement: .trailing)
  }
  
  private func style(_ button: UIButton, title: String? = nil, systemImageName: String, imagePlacement: NSDirectionalRectEdge, highlight: Bool = false) {
    
    let symbolConfig = UIImage.SymbolConfiguration(textStyle: .subheadline, scale: .default)
    button.setImage(.init(systemName: systemImageName, withConfiguration: symbolConfig), for: .normal)
    
    let foregroundColor = UIColor { traits in
      if traits.accessibilityContrast == .high {
        return #colorLiteral(red: 0.2384867668, green: 0.442800492, blue: 0.3663875461, alpha: 1)
      } else {
        return UIColor.tkAppTintColor
      }
    }
    
    var config = highlight ? UIButton.Configuration.borderedTinted() : UIButton.Configuration.plain()
    config.buttonSize = .mini
    config.imagePadding = 8
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
  }
  
  override func layoutSubviews() {
    // We switch dynamically to vertical layout if the natural size doesn't
    // fit horizontally OR if the either button is taller than wide.
    let timeSize = timeButton.intrinsicContentSize
    let transportSize = transportButton.intrinsicContentSize
    let fits = timeSize.width + transportSize.width + 32 < frame.width
            && timeSize.height < timeSize.width * 1.1
            && transportSize.height < transportSize.width * 1.1
    stackView.axis = fits ? .horizontal : .vertical
    
    super.layoutSubviews()
    
    timeButton.layer.cornerRadius = timeButton.frame.height / 2
    transportButton.layer.cornerRadius = transportButton.frame.height / 2
  }
  
  func setTimeLabel(_ text: String, highlight: Bool) {
    style(timeButton, title: text, systemImageName: "clock", imagePlacement: .leading, highlight: highlight)
  }
  
  func setTransport(isOpen: Bool? = nil) {
    if let isOpen {
      style(transportButton, title: Loc.Transport, systemImageName: isOpen ? "chevron.up" : "chevron.down", imagePlacement: .trailing)
      
      if isOpen {
        transportButton.accessibilityTraits.insert(.selected)
      } else {
        transportButton.accessibilityTraits.remove(.selected)
      }
      
    } else {
      style(transportButton, title: Loc.Transport, systemImageName: "slider.horizontal.3", imagePlacement: .leading)
    }
  }
  
  func hideTransportButton() {
    transportButton.isHidden = true
  }
  
  func update(preferredContentSizeCategory: UIContentSizeCategory) {
//    stackView.axis = preferredContentSizeCategory.isAccessibilityCategory ? .vertical : .horizontal
  }
  
}
