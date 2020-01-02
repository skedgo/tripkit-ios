//
//  TKUIServiceHeaderView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift
import TGCardViewController

class TKUIServiceHeaderView: UIView {
  @IBOutlet weak var accessibilityWrapper: UIView!
  @IBOutlet weak var accessibilityImageView: UIImageView!
  @IBOutlet weak var accessibilityTitleLabel: UILabel!

  @IBOutlet weak var occupancyWrapper: UIView!
  @IBOutlet weak var occupancyImageView: UIImageView!
  @IBOutlet weak var occupancyLabel: UILabel!
  @IBOutlet weak var trainOccupancyView: TKUITrainOccupancyView!
  @IBOutlet weak var trainOccupancyHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var trainOccupancyBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var occupancyUpdatedLabel: UILabel!

  @IBOutlet weak var alertWrapper: UIView!
  @IBOutlet weak var alertImageView: UIImageView!
  @IBOutlet weak var alertTitleLabel: UILabel!
  @IBOutlet weak var alertBodyLabel: UILabel!
  @IBOutlet weak var alertMoreButton: UIButton!
  
  @IBOutlet weak var expandyButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  private var disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceHeaderView {
    return Bundle(for: TKUIServiceHeaderView.self).loadNibNamed("TKUIServiceHeaderView", owner: self, options: nil)?.first as! TKUIServiceHeaderView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    accessibilityTitleLabel.textColor = .tkLabelPrimary
    
    occupancyLabel.textColor = .tkLabelPrimary
    occupancyUpdatedLabel.textColor = .tkLabelSecondary

    alertTitleLabel.textColor = .tkLabelPrimary
    alertBodyLabel.textColor = .tkLabelPrimary
    alertMoreButton.setTitle(Loc.Show, for: .normal)
    
    expandyButton.setImage(TGCard.arrowButtonImage(direction: .up, background: tintColor.withAlphaComponent(0.12), arrow: tintColor), for: .normal)
    expandyButton.setTitle(nil, for: .normal)
    expandyButton.accessibilityLabel = Loc.Collapse

    separator.backgroundColor = .tkLabelTertiary
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    
    expandyButton.setImage(TGCard.arrowButtonImage(direction: .up, background: tintColor.withAlphaComponent(0.12), arrow: tintColor), for: .normal)
  }
  
  private func updateAccessibility(_ accessibility: TKUIWheelchairAccessibility) {
    accessibilityImageView.image = accessibility.icon
    accessibilityTitleLabel.text = accessibility.title
  }
  
  private func updateRealTime(alerts: [Alert] = [], occupancies: Observable<([[TKAPI.VehicleOccupancy]], Date)>?) {
    
    if let sampleAlert = alerts.first {
      alertWrapper.isHidden = false

      alertImageView.image = sampleAlert.icon
      alertTitleLabel.text = alerts.count > 1
        ? Loc.Alerts(alerts.count)
        : sampleAlert.title ?? Loc.Alert
      alertBodyLabel.text = alerts.count > 1
        ? sampleAlert.title
        : sampleAlert.text

    } else {
      alertWrapper.isHidden = true
    }
    
    occupancyWrapper.isHidden = true
    occupancies?
      .subscribe(onNext: { [weak self] in
        self?.updateOccupancies($0.0, lastUpdated: $0.1)
      })
      .disposed(by: disposeBag)
  }
  
  private func updateOccupancies(_ occupancies: [[TKAPI.VehicleOccupancy]], lastUpdated: Date) {
    
    Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
      .startWith(0)
      .subscribe(onNext: { [weak self] _ in
        let duration = Date.durationString(forSeconds: lastUpdated.timeIntervalSinceNow * -1)
        let format = NSLocalizedString("Updated %@ ago", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Vehicle updated. (old key: VehicleUpdated)")
        let updatedTitle = String(format: format, duration)
        self?.occupancyUpdatedLabel.text = Loc.LastUpdated(date: updatedTitle)
      })
      .disposed(by: disposeBag)

    if occupancies.count > 1 || (occupancies.first?.count ?? 0) > 1, let average = TKAPI.VehicleOccupancy.average(in: occupancies.flatMap { $0 })
 {
      occupancyWrapper.isHidden = false
      
      occupancyImageView.image = average.standingPeople()
      occupancyLabel.text = average.localizedTitle

      trainOccupancyView.isHidden = false
      trainOccupancyView.occupancies = occupancies
      trainOccupancyHeightConstraint?.isActive = true
      trainOccupancyBottomConstraint?.isActive = true
      
    } else if let occupancy = occupancies.first?.first, occupancy != .unknown {
      occupancyWrapper.isHidden = false

      occupancyImageView.image = occupancy.standingPeople()
      occupancyLabel.text = occupancy.localizedTitle
      
      trainOccupancyView.isHidden = true
      trainOccupancyHeightConstraint?.isActive = false
      trainOccupancyBottomConstraint?.isActive = false

    } else {
      occupancyWrapper.isHidden = true
    }
    
    setNeedsUpdateConstraints()
  }

}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceHeaderView {
  func configure(with model: TKUIDepartureCellContent) {
    disposeBag = DisposeBag()
    
    updateAccessibility(model.wheelchairAccessibility)
    updateRealTime(alerts: model.alerts, occupancies: model.vehicleOccupancies)
    
    // stack views are weird; this should be in the front, but sometimes
    // gets put back
    bringSubviewToFront(expandyButton)
    
    updateConstraintsIfNeeded()
  }
}
