//
//  TKUINotificationView.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 12/1/22.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit
import RxSwift

class TKUINotificationView: UIView {
  
  @IBOutlet private weak var contentWrapper: UIView!

  @IBOutlet weak var notificationSwitch: UISwitch!
  
  @IBOutlet weak var titleImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  
  @IBOutlet weak var detailTitleLabel: UILabel!
  
  @IBOutlet weak var detailView: UIView!
  
  // Assuming this is constant first
  @IBOutlet weak var detailItem1: UILabel!
  @IBOutlet weak var detailItem2: UILabel!
  @IBOutlet weak var detailItem3: UILabel!
  @IBOutlet weak var detailItem4: UILabel!
  
  private(set) var disposeBag = DisposeBag()
  
  class func newInstance() -> TKUINotificationView {
    return Bundle(for: self).loadNibNamed("TKUINotificationView",
                                          owner: self,
                                          options: nil)?.first as! TKUINotificationView
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .clear
    contentWrapper.layer.cornerRadius = 6.0
    titleImageView.tintColor = .tkAppTintColor
  }
  
}

extension TKUINotificationView {
  
  func configure(with model: TKUITripOverviewViewModel) {
    
    
    notificationSwitch.rx.value
      .subscribe(onNext: { state in
        model.enableAlerts(state)
      })
      .disposed(by: disposeBag)
  }
  
}

