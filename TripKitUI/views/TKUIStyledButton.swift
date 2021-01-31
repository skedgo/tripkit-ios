//
//  TKUIStyledButton.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

@objc
open class TKUIStyledButton: UIButton {
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }
  
  private func didInit() {
    guard let label = titleLabel else { return }
    
    if let style = label.font.fontDescriptor.fontAttributes[.textStyle] as? String {
      label.font = TKStyleManager.customFont(forTextStyle: UIFont.TextStyle(rawValue: style))
    } else {
      label.font = TKStyleManager.systemFont(size: label.font.pointSize)
    }
  }
}
