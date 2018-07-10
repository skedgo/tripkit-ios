//
//  TKUIAlertCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 21/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit
import RxSwift

class TKUIAlertCell: UITableViewCell {
  
  @IBOutlet weak var iconView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var readMoreButton: UIButton!
  @IBOutlet weak var dateAddedLabel: UILabel!
  @IBOutlet weak var lastUpdatedLabel: UILabel!
  
  @IBOutlet weak var actionStackTopConstraint: NSLayoutConstraint!
  @IBOutlet private weak var dateAddedStackTopConstraint: NSLayoutConstraint!
  
  private var disposeBag = DisposeBag()
  var tappedOnLink = PublishSubject<URL>()
  
  @objc var alert: TKAlert? {
    didSet {
      updateContent()
    }
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    backgroundColor = TKStyleManager.backgroundColorForTileList()
    titleLabel.numberOfLines = 0
    removePadding(from: textView)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    cleanUp()
  }
  
  override func updateConstraints() {
    super.updateConstraints()    
    dateAddedStackTopConstraint.constant = dateAddedLabel.isHidden ? 0 : 16
    actionStackTopConstraint.constant = (readMoreButton.isHidden == true && lastUpdatedLabel.isHidden == true) ? 0 : 8
  }
  
  // MARK: -
  
  private func updateContent() {
    guard let alert = alert else { return }
    
    cleanUp()
    
    iconView.image = alert.icon
    if let URL = alert.iconURL {
      iconView.setImage(with: URL, placeholder: alert.icon)
    }
    
    titleLabel.text = alert.title
    textView.text = alert.text
    
    dateAddedLabel.isHidden = alert.startTime == nil
    if let dateAdded = alert.startTime {
      dateAddedLabel.text = Loc.From(date: TKStyleManager.string(for: dateAdded, for: .autoupdatingCurrent, showDate: true, showTime: false))      
    }

    lastUpdatedLabel.isHidden = alert.lastUpdated == nil
    if let lastUpdated = alert.lastUpdated {
      lastUpdatedLabel.text = Loc.LastUpdated(date: TKStyleManager.string(for: lastUpdated, for: .autoupdatingCurrent, showDate: true, showTime: false))
    }
    
    readMoreButton.isHidden = alert.infoURL == nil
    if let url = alert.infoURL {
      readMoreButton.rx.tap
        .subscribe(onNext: { [unowned self] in
          self.tappedOnLink.onNext(url)
        })
        .disposed(by: disposeBag)
    }
  }
  
  private func removePadding(from textView: UITextView) {
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = 0
  }
  
  private func cleanUp() {
    disposeBag = DisposeBag()
    tappedOnLink = PublishSubject<URL>()
  }
    
}
