//
//  TKUIResultsSectionFooterView.swift
//  TripKit
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TripKit

class TKUIResultsSectionFooterView: UITableViewHeaderFooterView {
  
  static let reuseIdentifier = "TKUIResultsSectionFooterView"
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var costLabel: UILabel!
  @IBOutlet weak var button: UIButton!
  @IBOutlet weak var leadingToTextConstraint: NSLayoutConstraint!
  
  var disposeBag = DisposeBag()
  
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
  
  private func didInit() {
    contentView.backgroundColor = .tkBackground
    
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.isHidden = true
    self.imageView = imageView
    contentView.addSubview(imageView)
    
    let costLabel = UILabel()
    costLabel.contentMode = .left
    costLabel.numberOfLines = 0
    costLabel.text = nil
    costLabel.textColor = .tkLabelSecondary
    costLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    costLabel.translatesAutoresizingMaskIntoConstraints = false
    costLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    costLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    self.costLabel = costLabel
    contentView.addSubview(costLabel)
    
    let button = UIButton(type: .system)
    button.contentHorizontalAlignment = .trailing
    button.setTitle("", for: .normal)
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
    button.tintColor = .tkAppTintColor
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    self.button = button
    contentView.addSubview(button)
    
    let topMarginConstraint = costLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)
    topMarginConstraint.priority = UILayoutPriority(rawValue: 999)
    
    let bottomMarginConstraint = contentView.bottomAnchor.constraint(equalTo: costLabel.bottomAnchor, constant: 6)
    bottomMarginConstraint.priority = UILayoutPriority(rawValue: 999)
    
    leadingToTextConstraint = costLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
    
    NSLayoutConstraint.activate([
      leadingToTextConstraint,
      button.leadingAnchor.constraint(equalTo: costLabel.trailingAnchor, constant: 16),
      contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16),
      
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      
      topMarginConstraint,
      costLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      costLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
      bottomMarginConstraint
    ])
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    costLabel.text = nil
    disposeBag = DisposeBag()
  }
}
  
// MARK: - Content

extension TKUIResultsSectionFooterView {

  typealias Action = TKUIRoutingResultsViewModel.SectionAction
  
  struct Content {
    var image: UIImage? = nil
    var cost: String? = nil
    var costAccessibility: String? = nil
    var action: Action? = nil
    var isWarning: Bool = false
  }

  func configure(_ content: Content, actionHandler: @escaping (Action) -> Void) {
    costLabel.accessibilityLabel = content.costAccessibility ?? content.cost
    costLabel.text = content.cost
    
    if content.isWarning {
      imageView.isHidden = false
      imageView.image = .iconAlert
      leadingToTextConstraint.constant = 16 + 8 + 20
      costLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
      costLabel.textColor = .tkStateError
    } else {
      imageView.isHidden = true
      imageView.image = nil
      leadingToTextConstraint.constant = 16
      costLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
      costLabel.textColor = .tkLabelSecondary
    }
    
    if let buttonContent = content.action {
      button.isHidden = false
      button.isEnabled = buttonContent.isEnabled
      button.setTitle(buttonContent.title, for: .normal)
      button.rx.tap
        .subscribe(onNext: {
          actionHandler(buttonContent)
        })
        .disposed(by: disposeBag)
    } else {
      button.isHidden = true
    }
  }
  
}

// MARK: Sizing

extension TKUIResultsSectionFooterView {
  
  private static let forSizing: TKUIResultsSectionFooterView = {
    return TKUIResultsSectionFooterView()
  }()
  
  static func height(for content: Content?, maxWidth: CGFloat) -> CGFloat {
    guard let content = content else { return .leastNonzeroMagnitude }

    let sizingFooter = TKUIResultsSectionFooterView.forSizing
    sizingFooter.leadingToTextConstraint.constant = content.isWarning ? 16 + 8 + 20 : 16
    
    sizingFooter.costLabel.text = content.cost
    sizingFooter.costLabel.font = content.isWarning ? TKStyleManager.boldCustomFont(forTextStyle: .footnote) : TKStyleManager.customFont(forTextStyle: .footnote)
    
    if let action = content.action {
      sizingFooter.button.isHidden = false
      sizingFooter.button.setTitle(action.title, for: .normal)
    } else {
      sizingFooter.button.isHidden = true
    }
    
    sizingFooter.contentView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
    let size = sizingFooter.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    return size.height
  }
  
}
