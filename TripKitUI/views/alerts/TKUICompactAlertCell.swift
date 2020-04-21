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
    imageView?.image = TripKitUIBundle.imageNamed("icon-alert")
    textLabel?.textColor = .tkLabelOnDark
  }
  
  func configure(_ alert: TKAPI.Alert) {
    contentView.backgroundColor = alert.severity.backgroundColor
    imageView?.tintColor = alert.severity.textColor
    textLabel?.text = alert.title
    textLabel?.textColor = alert.severity.textColor
  }
    
}
