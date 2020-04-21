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

  @IBOutlet weak var alertIcon: UIImageView!
  @IBOutlet weak var alertLabel: UILabel!

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
  
  func configure(_ alert: TKAPI.Alert) {
    contentView.backgroundColor = alert.severity.backgroundColor
    alertIcon?.tintColor = alert.severity.textColor
    alertLabel?.text = alert.title
    alertLabel?.textColor = alert.severity.textColor
  }
  
  private func didInit() {

    contentView.constraintsAffectingLayout(for: .vertical).forEach { $0.priority = UILayoutPriority(999) }
    
    let icon = UIImageView()
    icon.image = .iconAlert
    icon.contentMode = .scaleAspectFit
    icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 16).isActive = true
    icon.translatesAutoresizingMaskIntoConstraints = false
    self.alertIcon = icon
    
    let label = UILabel()
    label.numberOfLines = 1
    label.text = nil
    label.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    label.translatesAutoresizingMaskIntoConstraints = false
    self.alertLabel = label
    
    let stack = UIStackView(arrangedSubviews: [icon, label])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.distribution = .fill
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
        contentView.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 12),
        contentView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 16)
      ]
    )
  }
  
}
