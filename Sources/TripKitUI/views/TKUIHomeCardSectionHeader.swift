//
//  TKUIHomeCardSectionHeader.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 10/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TripKit

class TKUIHomeCardSectionHeader: UITableViewHeaderFooterView {
  
  private enum Constraint {
    static let top: CGFloat = 16.0
    static let leading: CGFloat = 16.0
    static let bottom: CGFloat = 16.0
    static let trailing: CGFloat = 16.0
    static let buttonHeight: CGFloat = 44.0
  }
  
  @IBOutlet private weak var label: UILabel?
  @IBOutlet private weak var button: UIButton!
  
  private var labelTopSpaceConstraint: NSLayoutConstraint?
  private var labelBottomSpaceConstraint: NSLayoutConstraint?
  
  var disposeBag = DisposeBag()
  
  private var minimize: Bool = false {
    didSet {
      labelTopSpaceConstraint?.constant = minimize ? 0 : Constraint.top
      labelBottomSpaceConstraint?.constant =  minimize ? 0 : Constraint.bottom
    }
  }
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    label?.text = nil
    button.setTitle(nil, for: .normal)
    disposeBag = DisposeBag()
  }
  
  func configure(with configuration: TKUIHomeHeaderConfiguration?, homeCard: TKUIHomeCard, onTap: @escaping (TKUIHomeCard.ComponentAction) -> Void) {
    if let configuration {
      if #available(iOS 26.0, *) {
        button.isHidden = false
        button.setTitle(configuration.title, for: .normal)
        if let action = configuration.action {
          button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
          button.rx.tap
            .subscribe(onNext: { _ in onTap(action.handler(homeCard)) })
            .disposed(by: disposeBag)
          button.isUserInteractionEnabled = true
        } else {
          button.setImage(nil, for: .normal)
          button.isUserInteractionEnabled = false
        }

      } else {
        label?.text = configuration.title
        if let action = configuration.action {
          button.isHidden = false
          button.setTitle(action.title.isEmpty ? Loc.SeeAll : action.title, for: .normal)
          button.rx.tap
            .subscribe(onNext: { _ in onTap(action.handler(homeCard)) })
            .disposed(by: disposeBag)
        } else {
          button.isHidden = true
          button.setTitle(nil, for: .normal)
        }
      }
      minimize = false
        
    } else {
      button.isHidden = true
      label?.text = nil
      button.setTitle(nil, for: .normal)
      button.setImage(nil, for: .normal)
      minimize = true
    }
    
    updateAccessibilityElements()
  }
  
  private func updateAccessibilityElements() {
    if minimize {
      accessibilityElements = []
    } else if button.isHidden {
      accessibilityElements = [label].compactMap { $0 }
    } else {
      // Override default order that'd start with the button
      accessibilityElements = [label, button].compactMap { $0 }
    }
  }
  
  private func didInit() {
    let wrapper = UIView()
#if targetEnvironment(macCatalyst)
    wrapper.backgroundColor = .clear
#else
    wrapper.backgroundColor = .tkBackground
#endif
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    
    if #available(iOS 26.0, *) {
      var config = UIButton.Configuration.plain()
      config.baseForegroundColor = .tkLabelSecondary
      config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
        var attrs = incoming
        attrs.font = TKStyleManager.semiboldCustomFont(forTextStyle: .title3)
        attrs.foregroundColor = .tkLabelPrimary
        return attrs
      }
      config.imagePlacement = .trailing
      config.imagePadding = 4
      
      let button = UIButton(configuration: config)
      button.contentHorizontalAlignment = .right
      button.translatesAutoresizingMaskIntoConstraints = false
      self.button = button
      wrapper.addSubview(button)

      updateAccessibilityElements()
      
      // Wrapper to content view
#if targetEnvironment(macCatalyst)
      contentView.backgroundColor = .clear
#else
      contentView.backgroundColor = .tkBackgroundGrouped
#endif

      contentView.addSubview(wrapper)
      NSLayoutConstraint.activate([
        wrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        wrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
        wrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        wrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
      ])
      
      // Label and button to wrapper
      button.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor).isActive = true
      button.topAnchor.constraint(equalTo: wrapper.topAnchor).isActive = true
      wrapper.bottomAnchor.constraint(equalTo: button.bottomAnchor).isActive = true
      wrapper.trailingAnchor.constraint(greaterThanOrEqualTo: button.trailingAnchor).isActive = true
      
      
    } else {
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

      updateAccessibilityElements()
      
      // Wrapper to content view
      #if targetEnvironment(macCatalyst)
      contentView.backgroundColor = .clear
      #else
      contentView.backgroundColor = .tkBackgroundGrouped
      #endif

      contentView.addSubview(wrapper)
      NSLayoutConstraint.activate([
        wrapper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        wrapper.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
        wrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        wrapper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
      ])
      
      // Label and button to wrapper
      label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: Constraint.leading).isActive = true
      let labelTopSpaceConstraint = label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: Constraint.top)
      labelTopSpaceConstraint.isActive = true
      self.labelTopSpaceConstraint = labelTopSpaceConstraint
      let labelBottomSpaceConstraint = wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: Constraint.bottom)
      labelBottomSpaceConstraint.isActive = true
      self.labelBottomSpaceConstraint = labelBottomSpaceConstraint
      
      button.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: Constraint.trailing).isActive = true
      wrapper.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: Constraint.trailing).isActive = true
      button.centerYAnchor.constraint(equalTo: label.centerYAnchor).isActive = true
      button.heightAnchor.constraint(equalToConstant: Constraint.buttonHeight).isActive = true
    }
  }
  
}
