//
//  TKUIAutocompletionResultCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 05.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUIAutocompletionResultCell: UITableViewCell {
  
  static let reuseIdentifier = "TKUIAutocompletionResultCell"
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

    // We set a background colour here to avoid ghosting.
    // reported here: https://redmine.buzzhives.com/issues/15589
    backgroundColor = .tkBackground
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

extension UILabel {
  fileprivate func set(text: String?, highlightRanges: [NSRange], textColor: UIColor) {
    guard let text else {
      self.attributedText = nil
      return
    }
    
    let attributed = NSMutableAttributedString(string: text, attributes: [
      .foregroundColor: textColor,
      .font: TKStyleManager.customFont(forTextStyle: .body),
    ])
    for range in highlightRanges {
      attributed.addAttribute(.font, value: TKStyleManager.boldCustomFont(forTextStyle: .body), range: range)
    }
    self.attributedText = attributed
  }
}

extension TKUIAutocompletionResultCell {
  
  private func configure(title: String, titleHighlightRanges: [NSRange] = [], subtitle: String? = nil, subtitleHighlightRanges: [NSRange] = [], image: UIImage? = nil) {
    imageView?.image = image
    imageView?.tintColor = .tkLabelPrimary
    textLabel?.set(text: title, highlightRanges: titleHighlightRanges, textColor: .tkLabelPrimary)
    detailTextLabel?.set(text: subtitle, highlightRanges: subtitleHighlightRanges, textColor: .tkLabelSecondary)
    contentView.alpha = 1
    accessoryView = nil
  }
  
  func configure(with item: TKUIAutocompletionViewModel.Item, onAccessoryTapped: ((TKUIAutocompletionViewModel.Item) -> Void)? = nil) {
    switch item {
    case .currentLocation: 
      configureCurrentLocation(with: item)
    case .action: 
      configureAction(with: item)
    case .autocompletion: 
      configureAutocompletion(with: item, onAccessoryTapped: onAccessoryTapped)
    }
  }
  
  private func configureCurrentLocation(with item: TKUIAutocompletionViewModel.Item) {
    guard case .currentLocation = item else { assertionFailure(); return }
    configure(title: Loc.CurrentLocation, image: TKAutocompletionResult.image(for: .currentLocation))
  }
  
  private func configureAutocompletion(with item: TKUIAutocompletionViewModel.Item, onAccessoryTapped: ((TKUIAutocompletionViewModel.Item) -> Void)?) {
    guard case .autocompletion(let autocompletion) = item else { assertionFailure(); return  }
    
    configure(
      title: autocompletion.title,
      titleHighlightRanges: autocompletion.completion.titleHighlightRanges,
      subtitle: autocompletion.subtitle,
      subtitleHighlightRanges: autocompletion.completion.subtitleHighlightRanges,
      image: autocompletion.image
    )
    contentView.alpha = autocompletion.showFaded ? 0.33 : 1
    
    if #available(iOS 14.0, *), let accessoryImage = autocompletion.accessoryImage, let target = onAccessoryTapped {
      let button = UIButton(primaryAction: UIAction(image: accessoryImage) { _ in
        target(item)
      })
      button.frame.size = CGSize(width: 44, height: 44)
      button.accessibilityLabel = autocompletion.accessoryAccessibilityLabel
      button.tintColor = .tkLabelTertiary
      accessoryView = button
    }
  }
  
  private func configureAction(with item: TKUIAutocompletionViewModel.Item) {
    guard case .action(let action) = item else { assertionFailure(); return  }
    configure(title: action.title)
  }
  
}
