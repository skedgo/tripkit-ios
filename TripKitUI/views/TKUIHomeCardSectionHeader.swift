//
//  TKUIHomeCardSectionHeader.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 10/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUIHomeCardSectionHeader: UITableViewHeaderFooterView {
  
  private enum Constraint {
    static let top: CGFloat = 8.0
    static let leading: CGFloat = 16.0
    static let bottom: CGFloat = 8.0
    static let trailing: CGFloat = 16.0
    static let buttonHeight: CGFloat = 44.0
  }
  
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var button: UIButton!
  
  var disposeBag = DisposeBag()
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    label.text = nil
    button.setTitle(nil, for: .normal)
    disposeBag = DisposeBag()
  }
  
  private func didInit() {
    let wrapper = UIView()
    #if targetEnvironment(macCatalyst)
    wrapper.backgroundColor = .clear
    #else
    wrapper.backgroundColor = .tkBackground
    #endif
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    
    let label = UILabel()
    label.textAlignment = .left
    label.font = TKStyleManager.semiboldCustomFont(forTextStyle: .subheadline)
    label.textColor = .tkLabelSecondary
    label.translatesAutoresizingMaskIntoConstraints = false
    self.label = label
    wrapper.addSubview(label)
    
    let button = UIButton(type: .system)
    button.tintColor = .tkAppTintColor
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    button.titleLabel?.textAlignment = .right
    button.translatesAutoresizingMaskIntoConstraints = false
    self.button = button
    wrapper.addSubview(button)
    
    // Override default order that'd start with the button
    accessibilityElements = [label, button]
    
    // Wrapper to content view
    contentView.addSubview(wrapper)
    NSLayoutConstraint.activate([
      wrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      wrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      wrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      wrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
    ])
    
    // Label and button to wrapper
    label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: Constraint.leading).isActive = true
    label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: Constraint.top).isActive = true
    wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: Constraint.bottom).isActive = true
    
    button.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: Constraint.trailing).isActive = true
    wrapper.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: Constraint.trailing).isActive = true
    button.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
    button.heightAnchor.constraint(equalToConstant: Constraint.buttonHeight).isActive = true
  }
  
}
