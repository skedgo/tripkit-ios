//
//  QuantityStepperAccessoryView.swift
//  TripKitUI-iOS
//
//  Created by Jules Gilos on 7/27/22.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class QuantityStepperAccessoryView: UIView {

  @IBOutlet weak var quantityLabel: UILabel!
  @IBOutlet weak var stepper: UIStepper!
  
  static func instantiate() -> QuantityStepperAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("QuantityStepperAccessoryView", owner: self, options: nil)!.first as? QuantityStepperAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
  }
}
