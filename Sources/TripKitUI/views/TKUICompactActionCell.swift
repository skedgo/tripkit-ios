//
//  TKUICompactActionCell.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 3/4/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUICompactActionCell: UICollectionViewCell {

  @IBOutlet private weak var imageWrapper: UIView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
  
  static let identifier = "TKUICompactActionCell"
  
  static let nib = UINib(nibName: "TKUICompactActionCell", bundle: .tripKitUI)
  
  var bold: Bool = false {
    didSet {
      updateUI()
    }
  }
  
  var onTap: ((TKUICompactActionCell) -> Bool)?
  
  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    titleLabel.text = nil
    updateUI()
  }
  
  override var isHighlighted: Bool {
    didSet {
      if isHighlighted {
        imageWrapper.backgroundColor = .tkBackgroundSelected
        imageWrapper.layer.borderColor = UIColor.tkLabelSecondary.cgColor
      } else {
        imageWrapper.backgroundColor = .tkBackground
        imageWrapper.layer.borderColor = UIColor.tkLabelQuarternary.cgColor
      }
    }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    isAccessibilityElement = true
    accessibilityTraits.insert(.button)
    
    contentView.backgroundColor = .clear
    
    imageWrapper.layer.cornerRadius = imageWrapper.bounds.width * 0.5
    
    titleLabel.textColor = .tkLabelPrimary
    titleLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    
    updateUI()
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateUI()
  }
  
  private func updateUI() {
    imageWrapper.backgroundColor = bold ? (tintColor ?? .clear) : .tkBackground
    imageWrapper.layer.borderWidth = bold ? 0 : 2
    imageWrapper.layer.borderColor = bold ? nil : UIColor.tkLabelQuarternary.cgColor
    imageWrapper.tintColor = bold ? .tkBackground : .tkLabelSecondary
  }
  
}

extension TKUICompactActionCell {
  
  static func newInstance() -> TKUICompactActionCell {
    return Bundle.tripKitUI.loadNibNamed("TKUICompactActionCell", owner: self, options: nil)?.first as! TKUICompactActionCell
  }
  
}
