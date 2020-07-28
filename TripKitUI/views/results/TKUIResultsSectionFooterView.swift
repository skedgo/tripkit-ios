//
//  TKUIResultsSectionFooterView.swift
//  TripKit
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUIResultsSectionFooterView: UITableViewHeaderFooterView {
  
  static let forSizing: TKUIResultsSectionFooterView = {
    let footer = TKUIResultsSectionFooterView()
    footer.costLabel.text = "Size me"
    return footer
  }()
  
  static let reuseIdentifier = "TKUIResultsSectionFooterView"
  
  @IBOutlet weak var costLabel: UILabel!
  @IBOutlet weak var button: UIButton!
  
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
    
    let costLabel = UILabel()
    costLabel.contentMode = .left
    costLabel.numberOfLines = 1
    costLabel.text = nil
    costLabel.textColor = .tkLabelSecondary
    costLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
    costLabel.translatesAutoresizingMaskIntoConstraints = false
    costLabel.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
    costLabel.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
    self.costLabel = costLabel
    contentView.addSubview(costLabel)
    
    let button = UIButton(type: .system)
    button.contentHorizontalAlignment = .trailing
    button.setTitle("", for: .normal)
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
    button.tintColor = .tkAppTintColor
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setContentHuggingPriority(.defaultLow, for: .horizontal)
    button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    self.button = button
    contentView.addSubview(button)
    
    NSLayoutConstraint.activate([
      costLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      button.leadingAnchor.constraint(equalTo: costLabel.trailingAnchor, constant: 16),
      contentView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: 16),
      
      costLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
      costLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      contentView.bottomAnchor.constraint(equalTo: costLabel.bottomAnchor, constant: 6)
    ])
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    costLabel.text = nil
    disposeBag = DisposeBag()
  }
  
  var cost: String? {
    get { costLabel.text }
    set { costLabel.text = newValue }
  }
  
  var attributedCost: NSAttributedString? {
    get { costLabel.attributedText }
    set { costLabel.attributedText = newValue }
  }
  
}
