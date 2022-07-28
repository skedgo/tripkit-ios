//
//  QuantityStepperAccessoryView.swift
//  TripKitUI-iOS
//
//  Created by Jules Gilos on 7/27/22.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

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

// MARK: Setters

extension QuantityStepperAccessoryView {
  
  func setQuantity(_ quantity: Int) {
    stepper.value = Double(quantity)
    quantityLabel.text = "\(quantity)"
  }
  
}

// MARK: Observers

extension QuantityStepperAccessoryView {
  
  func amountChanged() -> Observable<Int> {
    return stepper.rx.value
      .map { Int($0) }
  }
}
