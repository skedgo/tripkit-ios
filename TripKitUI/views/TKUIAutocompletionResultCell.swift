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

  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
}

extension TKUIAutocompletionResultCell {
  
  func configure(with item: TKUIAutocompletionViewModel.Item, onAccessoryTapped: PublishSubject<TKUIAutocompletionViewModel.Item>?) {
    disposeBag = DisposeBag()
    
    imageView?.image = item.image
    imageView?.tintColor = #colorLiteral(red: 0.8500000238, green: 0.8500000238, blue: 0.8500000238, alpha: 1) // From SkedGo default icons
    textLabel?.text = item.title
    textLabel?.textColor = SGStyleManager.darkTextColor()
    detailTextLabel?.text = item.subtitle
    detailTextLabel?.textColor = SGStyleManager.lightTextColor()
    contentView.alpha = item.showFaded ? 0.33 : 1
    
    if let accessoryImage = item.accessoryImage, let target = onAccessoryTapped {
      let button = SGStyleManager.cellAccessoryButton(with: accessoryImage, target: nil, action: nil)
      button.rx.tap
        .map { _ in item }
        .bind(to: target)
        .disposed(by: disposeBag)
      accessoryView = button
    } else {
      accessoryView = nil
    }

  }
  
}
