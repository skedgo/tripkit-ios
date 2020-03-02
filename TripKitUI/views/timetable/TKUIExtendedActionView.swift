//
//  TKUITimetableActionView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIExtendedActionView: UIView {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var label: UILabel!
  
  private var tapGestureRecognizer: UITapGestureRecognizer!
  
  var bold: Bool = false {
    didSet {
      updateForBoldness()
    }
  }

  var onTap: ((TKUIExtendedActionView) -> Void)?
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = frame.size.height / 2
  }
  
  static func newInstance() -> TKUIExtendedActionView {
    let view = Bundle(for: self).loadNibNamed("TKUIExtendedActionView", owner: self, options: nil)?.first as! TKUIExtendedActionView
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    if #available(iOS 13.0, *) {
      layer.cornerCurve = .continuous
    }
    
    backgroundColor = .clear
    
    let tapper = UITapGestureRecognizer(target: self, action: #selector(tapperFired(_:)))
    self.addGestureRecognizer(tapper)
    
    label.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
    
    updateForBoldness()
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateForBoldness()
  }
  
  @objc
  func tapperFired(_ recognizer: UITapGestureRecognizer) {
    onTap?(self)
  }
  
  private func updateForBoldness() {
    if bold, let tintColor = self.tintColor {
      backgroundColor = tintColor
      layer.borderWidth = 0
      layer.borderColor = nil
      
      let textColor: UIColor = tintColor.isDark() ? .tkLabelOnDark : .tkLabelOnLight
      imageView.tintColor = textColor
      label.textColor = textColor
    } else {
      backgroundColor = .tkBackground
      layer.borderWidth = 2
      layer.borderColor = UIColor.tkLabelQuarternary.cgColor
      imageView.tintColor = .tkLabelPrimary
      label.textColor = .tkLabelPrimary
    }
  }
  
}
