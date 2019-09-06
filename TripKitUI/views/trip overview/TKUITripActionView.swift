//
//  TKUITripActionView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import UIKit

class TKUITripActionView: UIView {
    
  @IBOutlet weak var imageWrapper: UIView!
  @IBOutlet weak var imageView: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  
  var bold: Bool = false {
    didSet {
      updateForBoldness()
    }
  }
  
  private var tapGestureRecognizer: UITapGestureRecognizer!
  
  var onTap: ((TKUITripActionView) -> Void)?
  
  class func newInstance() -> TKUITripActionView {
    let view = Bundle(for: self).loadNibNamed("TKUITripActionView", owner: self, options: nil)?.first as! TKUITripActionView
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear
    
    let tapper = UITapGestureRecognizer(target: self, action: #selector(tapperFired(_:)))
    self.addGestureRecognizer(tapper)
    
    imageWrapper.layer.cornerRadius = imageWrapper.bounds.width / 2
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
    if bold {
      imageWrapper.backgroundColor = tintColor ?? .clear
      imageWrapper.layer.borderWidth = 0
      imageWrapper.layer.borderColor = nil
      imageWrapper.tintColor = .tkBackground
    } else {
      imageWrapper.backgroundColor = .tkBackground
      imageWrapper.layer.borderWidth = 2
      imageWrapper.layer.borderColor = UIColor.tkLabelQuarternary.cgColor
      imageWrapper.tintColor = .tkLabelSecondary
    }
  }
}
