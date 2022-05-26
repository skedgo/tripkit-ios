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
  
  static let identifier = "TKUICompactActionCell"
  
  static let nib = UINib(nibName: "TKUICompactActionCell", bundle: .tripKitUI)
  
  var style: TKUICardActionStyle = .normal {
    didSet {
      updateForStyle()
    }
  }
  
  var onTap: ((TKUICompactActionCell) -> Bool)?
  
  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    titleLabel.text = nil
    updateForStyle()
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
    
    updateForStyle()
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateForStyle()
  }
  
  private func updateForStyle() {
    switch style {
    case .bold, .destructive:
      let background: UIColor
      if style == .destructive {
        background = .tkStateError
      } else {
        background = tintColor ?? .clear
      }
      
      imageWrapper.backgroundColor = background
      imageWrapper.layer.borderWidth = 0
      imageWrapper.layer.borderColor = nil
      imageWrapper.tintColor = .tkBackground

    case .normal:
      imageWrapper.backgroundColor = .tkBackground
      imageWrapper.layer.borderWidth = 2
      imageWrapper.layer.borderColor = UIColor.tkLabelQuarternary.cgColor
      imageWrapper.tintColor = .tkLabelSecondary
    }
  }
  
}

extension TKUICompactActionCell {
  
  static func newInstance() -> TKUICompactActionCell {
    return Bundle.tripKitUI.loadNibNamed("TKUICompactActionCell", owner: self, options: nil)?.first as! TKUICompactActionCell
  }
  
}
