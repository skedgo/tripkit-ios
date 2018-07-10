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
  
  private var tapGestureRecognizer: UITapGestureRecognizer!
  
  var onTap: ((TKUITripActionView) -> Void)?
  
  class func newInstance() -> TKUITripActionView {
    let view = Bundle(for: self).loadNibNamed("TKUITripActionView", owner: self, options: nil)?.first as! TKUITripActionView
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    let tapper = UITapGestureRecognizer(target: self, action: #selector(tapperFired(_:)))
    self.addGestureRecognizer(tapper)
  }
  
  @objc
  func tapperFired(_ recognizer: UITapGestureRecognizer) {
    onTap?(self)
  }
}
