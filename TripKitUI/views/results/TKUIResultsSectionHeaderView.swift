//
//  TKUIResultsSectionHeaderView.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 04.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUIResultsSectionHeaderView: UITableViewHeaderFooterView {

  static let forSizing: TKUIResultsSectionHeaderView = {
    let header = TKUIResultsSectionHeaderView()
    header.badgeIcon.image = .badgeLeaf
    return header
  }()
  
  static let reuseIdentifier = "TKUIResultsSectionHeaderView"
  
  @IBOutlet weak var wrapper: UIView!
  @IBOutlet weak var badgeIcon: UIImageView!
  @IBOutlet weak var badgeLabel: UILabel!
  
  private init() {
    super.init(reuseIdentifier: nil)
    didInit()
  }
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    didInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()

    badgeIcon.image = nil
    badgeLabel.text = nil
  }
  
  var badge: (icon: UIImage?, text: String, color: UIColor)? {
    get {
      (badgeIcon.image, badgeLabel.text ?? "", badgeLabel.textColor ?? .tkLabelPrimary)
    }
    set {
      badgeIcon.image = newValue?.icon
      badgeIcon.tintColor = newValue?.color
      badgeLabel.text = newValue?.text
      badgeLabel.textColor = newValue?.color
    }
  }
  
  private func didInit() {
    let wrapper = UIView()
    wrapper.backgroundColor = .tkBackgroundBelowTile
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    self.wrapper = wrapper
    contentView.addSubview(wrapper)
    NSLayoutConstraint.activate([
      wrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
      wrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      contentView.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: 0),
      contentView.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: 0)
    ])
    
    let badgeIcon = UIImageView()
    badgeIcon.contentMode = .scaleAspectFit
    badgeIcon.tintColor = .tkFilledButtonTextColor
    badgeIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
    let heightConstraint = badgeIcon.heightAnchor.constraint(equalToConstant: 16)
    heightConstraint.priority = UILayoutPriority(rawValue: 999)
    heightConstraint.isActive = true
    badgeIcon.translatesAutoresizingMaskIntoConstraints = false
    self.badgeIcon = badgeIcon
    wrapper.addSubview(badgeIcon)
    
    let badgeLabel = UILabel()
    badgeLabel.numberOfLines = 1
    badgeLabel.text = nil
    badgeLabel.textColor = .tkFilledButtonTextColor
    badgeLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
    badgeLabel.translatesAutoresizingMaskIntoConstraints = false
    self.badgeLabel = badgeLabel
    wrapper.addSubview(badgeLabel)
    
    NSLayoutConstraint.activate([
      badgeIcon.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
      badgeLabel.leadingAnchor.constraint(equalTo: badgeIcon.trailingAnchor, constant: 8),
      wrapper.trailingAnchor.constraint(equalTo: badgeLabel.trailingAnchor, constant: 16),
      
      badgeIcon.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 16),
      badgeLabel.centerYAnchor.constraint(equalTo: badgeIcon.centerYAnchor),
      wrapper.bottomAnchor.constraint(equalTo: badgeIcon.bottomAnchor, constant: 4)
    ])
  }
  
}
