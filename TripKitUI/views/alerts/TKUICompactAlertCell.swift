//
//  TKUICompactAlertCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 21.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUICompactAlertCell: UITableViewCell {
  
  static let reuseIdentifier = "TKUICompactAlertCell"

  override convenience init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    self.init()
  }
  
  init() {
    super.init(style: .default, reuseIdentifier: Self.reuseIdentifier)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }
  
  private func didInit() {
    contentView.backgroundColor = #colorLiteral(red: 0.7882352941, green: 0.3254901961, blue: 0.2745098039, alpha: 0.8997221057)
    imageView?.image = TripKitUIBundle.imageNamed("icon-warning-desc-white")
    textLabel?.textColor = .tkLabelOnDark
  }
    
}
