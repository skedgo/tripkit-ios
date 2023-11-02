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
  @IBOutlet var notificationKindStack: UIStackView!
  
  // Assuming this is constant first
  @IBOutlet weak var detailView1: UIView!
  @IBOutlet weak var detailItem1: UILabel!
  @IBOutlet weak var detailView2: UIView!
  @IBOutlet weak var detailItem2: UILabel!
  @IBOutlet weak var detailView3: UIView!
  @IBOutlet weak var detailItem3: UILabel!
  @IBOutlet weak var detailView4: UIView!
  @IBOutlet weak var detailItem4: UILabel!
  @IBOutlet weak var detailView5: UIView!
  @IBOutlet weak var detailItem5: UILabel!

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
    
    titleLabel.text = Loc.TripNotifications
    detailTitleLabel.text = Loc.TripNotificationsSubtitle
  }
  
  func updateAvailableKinds(_ notificationKinds: Set<TKAPI.TripNotification.MessageKind>, includeTimeToLeaveNotification: Bool = true) {
    
    func views(for kind: TKAPI.TripNotification.MessageKind) -> (UIView, UILabel) {
      switch kind {
      case .arrivingAtYourStop: return (detailView2, detailItem2)
      case .nextStopIsYours: return (detailView3, detailItem3)
      case .tripEnd: return (detailView4, detailItem4)
      case .tripStart: return (detailView1, detailItem1)
      case .vehicleIsApproaching: return (detailView5, detailItem5)
      }
    }
    
    for kind in TKAPI.TripNotification.MessageKind.allCases {
      let (view, label) = views(for: kind)
      view.alpha = notificationKinds.contains(kind) ? 1 : 0.3
      label.text = kind.label
    }
    
    views(for: .tripStart).0.isHidden = !includeTimeToLeaveNotification
    views(for: .vehicleIsApproaching).0.isHidden = !TKUINotificationManager.shared.isSubscribed(to: .pushNotifications)
    
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

extension TKAPI.TripNotification.MessageKind {
  var label: String {
    switch self {
    case .tripStart:
      return Loc.TripNotificationsTripStart
    case .vehicleIsApproaching:
      return Loc.TripNotificationsVehicleApproaching
    case .arrivingAtYourStop:
      return Loc.TripNotificationsArrivingAtStop
    case .nextStopIsYours:
      return Loc.TripNotificationsNextStop
    case .tripEnd:
      return Loc.TripNotificationsTripEnd
    }
  }
}
