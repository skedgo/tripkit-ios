//
//  TKUIAutocompletionResultCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 05.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa

class TKUIAutocompletionResultCell: UITableViewCell {
  
  static let reuseIdentifier = "TKUIAutocompletionResultCell"
  
  private var disposeBag: DisposeBag!

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

extension TKUIAutocompletionResultCell {
  
  func configure(with item: TKUIAutocompletionViewModel.Item, onAccessoryTapped: PublishSubject<TKUIAutocompletionViewModel.Item>? = nil) {
    disposeBag = DisposeBag()
    
    switch item {
    case .currentLocation: configureCurrentLocation(with: item)
    case .action: configureAction(with: item)
    case .autocompletion: configureAutocompletion(with: item, onAccessoryTapped: onAccessoryTapped)
    }

  }
  
  private func configureCurrentLocation(with item: TKUIAutocompletionViewModel.Item) {
    guard case .currentLocation = item else { assertionFailure(); return }
    
    imageView?.image = TKAutocompletionResult.image(forType: .currentLocation)
    imageView?.tintColor = .tkLabelPrimary
    textLabel?.text = Loc.CurrentLocation
    textLabel?.textColor = .tkLabelPrimary
    detailTextLabel?.text = nil
    accessoryView = nil
  }
  
  private func configureAutocompletion(with item: TKUIAutocompletionViewModel.Item, onAccessoryTapped: PublishSubject<TKUIAutocompletionViewModel.Item>?) {
    guard case .autocompletion(let autocompletion) = item else { assertionFailure(); return  }
    
    imageView?.image = autocompletion.image
    imageView?.tintColor = .tkLabelPrimary // From SkedGo default icons
    textLabel?.text = autocompletion.title
    textLabel?.textColor = .tkLabelPrimary
    detailTextLabel?.text = autocompletion.subtitle
    detailTextLabel?.textColor = .tkLabelSecondary
    contentView.alpha = autocompletion.showFaded ? 0.33 : 1
    
    if let accessoryImage = autocompletion.accessoryImage, let target = onAccessoryTapped {
      let button = TKStyleManager.cellAccessoryButton(with: accessoryImage, target: nil, action: nil)
      button.rx.tap
        .map { _ in item }
        .bind(to: target)
        .disposed(by: disposeBag)
      accessoryView = button
    } else {
      accessoryView = nil
    }
  }
  
  private func configureAction(with item: TKUIAutocompletionViewModel.Item) {
    guard case .action(let action) = item else { assertionFailure(); return  }
    
    imageView?.image = nil
    textLabel?.text = action.title
    textLabel?.textColor = .tkLabelPrimary
    detailTextLabel?.text = nil
    contentView.alpha = 1
    accessoryView = nil
  }
  
}
