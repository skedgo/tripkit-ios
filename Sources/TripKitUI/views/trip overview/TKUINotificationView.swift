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
  @IBOutlet weak var detailView1: UIView!
  @IBOutlet weak var detailItem1: UILabel!
  @IBOutlet weak var detailView2: UIView!
  @IBOutlet weak var detailItem2: UILabel!
  @IBOutlet weak var detailView3: UIView!
  @IBOutlet weak var detailItem3: UILabel!
  @IBOutlet weak var detailView4: UIView!
  @IBOutlet weak var detailItem4: UILabel!
    
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
  
  func updateAvailableKinds(_ notificationKinds: Set<TKAPI.TripNotification.MessageKind>) {
    detailView1.alpha = notificationKinds.contains(.tripStart) ? 1 : 0.3
    detailView2.alpha = notificationKinds.contains(.arrivingAtYourStop) ? 1 : 0.3
    detailView3.alpha = notificationKinds.contains(.nextStopIsYours) ? 1 : 0.3
    detailView4.alpha = notificationKinds.contains(.tripEnd) ? 1 : 0.3
    notificationSwitch.isEnabled = !notificationKinds.isEmpty
  }
  
}
