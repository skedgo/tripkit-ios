//
//  TKUITimetableActionView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUIExtendedActionView: UIView {

  @IBOutlet weak var wrapper: UIView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var label: UILabel!
  
  private var tapGestureRecognizer: UITapGestureRecognizer!
  
  var style: TKUICardActionStyle = .normal {
    didSet {
      updateForStyle()
    }
  }

  var onTap: ((TKUIExtendedActionView) -> Void)?
    
  static func newInstance() -> TKUIExtendedActionView {
    let view = Bundle(for: self).loadNibNamed("TKUIExtendedActionView", owner: self, options: nil)?.first as! TKUIExtendedActionView
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    layer.cornerRadius = 18
    layer.cornerCurve = .continuous
    
    backgroundColor = .clear
    
    let tapper = UITapGestureRecognizer(target: self, action: #selector(tapperFired(_:)))
    self.addGestureRecognizer(tapper)
    
    label.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
    
    updateForStyle()
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    updateForStyle()
  }
  
  @objc
  func tapperFired(_ recognizer: UITapGestureRecognizer) {
    onTap?(self)
  }
  
  private func updateForStyle() {
    switch style {
    case .bold, .destructive:
      let background: UIColor
      if style == .destructive {
        background = .tkStateError
      } else {
        background = tintColor ?? .tkAppTintColor
      }
      
      backgroundColor = background
      layer.borderWidth = 0
      layer.borderColor = nil
      
      let textColor: UIColor = background.isDark ? .tkLabelOnDark : .tkLabelOnLight
      imageView.tintColor = textColor
      label.textColor = textColor

    case .normal:
      backgroundColor = .tkBackground
      layer.borderWidth = 2
      layer.borderColor = UIColor.tkLabelQuarternary.cgColor
      imageView.tintColor = .tkLabelPrimary
      label.textColor = .tkLabelPrimary
    }
  }
  
}
