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
    
  @IBOutlet weak var separator: UIView!
  
  @IBOutlet var labels: [UILabel]!
  @IBOutlet var detailImageViews: [UIImageView]!
  
  class func newInstance() -> TKUINotificationView {
    return Bundle(for: self).loadNibNamed("TKUINotificationView",
                                          owner: self,
                                          options: nil)?.first as! TKUINotificationView
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    contentWrapper.layer.cornerRadius = 6.0
    setupColors()
  }
  
  func updateAvailableKinds(_ notificationKinds: Set<TKAPI.TripNotification.MessageKind>, includeTimeToLeaveNotification: Bool = true) {
    detailView1.alpha = notificationKinds.contains(.tripStart) ? 1 : 0.3
    detailView2.alpha = notificationKinds.contains(.arrivingAtYourStop) ? 1 : 0.3
    detailView3.alpha = notificationKinds.contains(.nextStopIsYours) ? 1 : 0.3
    detailView4.alpha = notificationKinds.contains(.tripEnd) ? 1 : 0.3
    detailView1.isHidden = !includeTimeToLeaveNotification
    notificationSwitch.isEnabled = !notificationKinds.isEmpty
  }
    
  func setupColors() {
    // Xib selected custom colors only use the selected color and does not use the dark mode color when in dark mode. These are programatically set so that the dark mode colors are used.
    backgroundColor = .clear
    contentWrapper.backgroundColor = .tkBackgroundSecondary
    separator.backgroundColor = .tkBarSecondary
    titleImageView.tintColor = .tkAppTintColor
    labels.forEach { $0.textColor = .tkLabelPrimary }
    detailImageViews.forEach { $0.tintColor = .tkLabelPrimary }
  }
  
}
