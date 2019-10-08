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
  
  static let reuseIdentifier = "TKUIResultsSectionFooterView"
  
  @IBOutlet weak var costLabel: UILabel!
  @IBOutlet weak var button: UIButton!
  
  var disposeBag = DisposeBag()
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    didInit()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
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
    costLabel.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
    costLabel.setContentCompressionResistancePriority(UILayoutPriority(750), for: .horizontal)
    self.costLabel = costLabel
    
    let button = UIButton(type: .system)
    if #available(iOS 11.0, *) {
      button.contentHorizontalAlignment = .trailing
    } else {
      button.contentHorizontalAlignment = .right
    }
    // TODO: Localise or should we use "Loc.MoreResults"?
    button.setTitle("More", for: .normal)
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .footnote)
    button.tintColor = .tkAppTintColor
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setContentHuggingPriority(UILayoutPriority(250), for: .horizontal)
    button.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
    self.button = button
    
    let stack = UIStackView(arrangedSubviews: [costLabel, button])
    stack.axis = .horizontal
    stack.alignment = .fill
    stack.distribution = .fill
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
        contentView.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: 16),
        contentView.bottomAnchor.constraint(equalTo: stack.bottomAnchor, constant: 6)
      ]
    )
    
    // When table view animates sections in and out, the layout system somehow
    // assumes a height that is significantly smaller than required. This is a
    // workaround.
    contentView.constraintsAffectingLayout(for: .vertical).forEach { $0.priority = UILayoutPriority(999) }
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
