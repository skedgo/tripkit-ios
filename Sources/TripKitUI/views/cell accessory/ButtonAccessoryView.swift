//
//  ButtonAccessoryView.swift
//  TripKitUI-iOS
//
//  Created by Jules Gilos on 7/27/22.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import TripKit

import RxSwift
import RxCocoa

class ButtonAccessoryView: UIView {

  @IBOutlet weak var button: UIButton!
  
  static func instantiate() -> ButtonAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("ButtonAccessoryView", owner: self, options: nil)!.first as? ButtonAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
    // button.tintColor = .tkAppTintColor
    
    // Review:
    // 1. maybe should get own color declaration for buttons
    // 2. standardize button style (see xib for content insets)
    button.tintColor = .tkAppTintColor
    button.contentHorizontalAlignment = .center
    button.layer.cornerRadius = button.frame.height * 0.5
    button.titleLabel?.font = TKStyleManager.semiboldCustomFont(forTextStyle: .footnote)
  }
}

// MARK: Observers

extension ButtonAccessoryView {
  
  func buttonTapped() -> Observable<Void> {
    return button.rx.tap.asObservable()
  }
  
}

