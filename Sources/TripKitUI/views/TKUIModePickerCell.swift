//
//  TKUIModePickerCell.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 12/11/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

class TKUIModePickerCell: UICollectionViewCell {
  
  static let reuseIdentifier = "TKUIModePickerCell"
  
  static let nib = UINib(nibName: "TKUIModePickerCell", bundle: .tripKitUI)
  
  @IBOutlet weak var contentWrapper: UIView!
  @IBOutlet weak var leftImageView: UIImageView!
  @IBOutlet weak var rightImageView: UIImageView!
  
  @IBOutlet private weak var spacingBetweenImages: NSLayoutConstraint!
  @IBOutlet private weak var rightImageWidthConstraint: NSLayoutConstraint!
  @IBOutlet private weak var rightImageHeightConstraint: NSLayoutConstraint!
  
  static func newInstance() -> TKUIModePickerCell {
    return Bundle.tripKitUI.loadNibNamed("TKUIModePickerCell", owner: self, options: nil)?.first as! TKUIModePickerCell
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    
    contentWrapper.backgroundColor = .clear
    contentWrapper.layer.cornerRadius = contentWrapper.frame.height * 0.5
    
    leftImageView.layer.cornerCurve = .continuous
    leftImageView.layer.cornerRadius = leftImageView.frame.width * 0.5
    
    rightImageView.layer.cornerCurve = .continuous
    rightImageView.layer.cornerRadius = rightImageView.frame.width * 0.5
    hideRightImage(true)
  }
  
  func hideRightImage(_ hide: Bool) {
    rightImageView.isHidden = hide
    spacingBetweenImages.constant = hide ? 0 : 0
    rightImageWidthConstraint.constant = hide ? 0 : 40
    rightImageHeightConstraint.constant = hide ? 0 : 40
  }

}
