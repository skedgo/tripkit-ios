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

  @IBOutlet weak var timeButton: UIButton!
  @IBOutlet weak var transportButton: UIButton!
  
  static func instantiate() -> TKUIResultsAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUIResultsAccessoryView", owner: nil, options: nil)!.first as? TKUIResultsAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    timeButton.setTitle(nil, for: .normal)
    transportButton.setTitle(Loc.Transport, for: .normal)
  }

}
