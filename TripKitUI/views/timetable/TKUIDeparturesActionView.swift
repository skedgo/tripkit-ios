//
//  TKUIDeparturesActionView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIDeparturesActionView: UIView {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var label: UILabel!
  
  private var tapGestureRecognizer: UITapGestureRecognizer!
  
  var bold: Bool = false {
    didSet {
      updateForBoldness()
    }
  }

  var onTap: ((TKUIDeparturesActionView) -> Void)?
  
  override var frame: CGRect {
    didSet {
      layer.cornerRadius = frame.size.height / 2
    }
  }
  
  class func newInstance() -> TKUIDeparturesActionView {
    let view = Bundle(for: self).loadNibNamed("TKUIDeparturesActionView", owner: self, options: nil)?.first as! TKUIDeparturesActionView
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
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
    if bold {
      backgroundColor = tintColor ?? .clear
      layer.borderWidth = 0
      layer.borderColor = nil
      imageView.tintColor = .tkBackground
      label.textColor = .tkBackground
    } else {
      backgroundColor = .tkBackground
      layer.borderWidth = 2
      layer.borderColor = UIColor.tkLabelQuarternary.cgColor
      imageView.tintColor = .tkLabelPrimary
      label.textColor = .tkLabelPrimary
    }
  }
  
}
