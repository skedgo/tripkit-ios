//
//  TKUIResultsSectionHeaderView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 04.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIResultsSectionHeaderView: UITableViewHeaderFooterView {

  static let reuseIdentifier = "TKUIResultsSectionHeaderView"
  
  @IBOutlet weak var wrapper: UIView!
  @IBOutlet weak var badgeIcon: UIImageView!
  @IBOutlet weak var badgeLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    wrapper.backgroundColor = .tkBackgroundTile
    
    badgeIcon.image = nil
    badgeIcon.tintColor = .tkFilledButtonTextColor
    badgeLabel.text = nil
    badgeLabel.textColor = .tkFilledButtonTextColor
    badgeLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
  }
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    didInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()

    badgeIcon.image = nil
    badgeLabel.text = nil
  }
  
  var badge: (icon: UIImage?, text: String, color: UIColor) {
    get {
      (badgeIcon.image, badgeLabel.text ?? "", badgeLabel.textColor ?? .tkLabelPrimary)
    }
    set {
      badgeIcon.image = newValue.icon
      badgeIcon.tintColor = newValue.color
      badgeLabel.text = newValue.text
      badgeLabel.textColor = newValue.color
    }
  }
  
  private func didInit() {
    let wrapper = UIView()
    wrapper.backgroundColor = .tkBackgroundTile
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    self.wrapper = wrapper
    contentView.addSubview(wrapper)
    NSLayoutConstraint.activate([
      wrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
      wrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      contentView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: 0),
      contentView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: 0)
    ])
    
    contentView.constraintsAffectingLayout(for: .vertical).forEach { $0.priority = UILayoutPriority(999) }
    
    let badgeIcon = UIImageView()
    badgeIcon.contentMode = .scaleAspectFit
    badgeIcon.tintColor = .tkFilledButtonTextColor
    badgeIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
    badgeIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
    badgeIcon.translatesAutoresizingMaskIntoConstraints = false
    self.badgeIcon = badgeIcon
    
    let badgeLabel = UILabel()
    badgeLabel.numberOfLines = 1
    badgeLabel.text = nil
    badgeLabel.textColor = .tkFilledButtonTextColor
    badgeLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    self.badgeLabel = badgeLabel
    
    let stack = UIStackView(arrangedSubviews: [badgeIcon, badgeLabel])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.distribution = .fill
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(stack)
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
        stack.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 16),
        wrapper.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 5),
        wrapper.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 16)
      ]
    )
  }
  
}
