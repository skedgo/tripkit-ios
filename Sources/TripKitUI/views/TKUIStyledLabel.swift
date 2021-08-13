//
//  TKUIStyledLabel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

@objc
open class TKUIStyledLabel: UILabel {
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }
  
  private func didInit() {
    if let style = font.fontDescriptor.fontAttributes[.textStyle] as? String {
      font = TKStyleManager.customFont(forTextStyle: UIFont.TextStyle(rawValue: style))
    } else {
      font = TKStyleManager.systemFont(size: font.pointSize)
    }
  }
}
