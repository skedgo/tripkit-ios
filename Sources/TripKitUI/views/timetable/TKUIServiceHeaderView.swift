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

import TripKit

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
  @IBOutlet weak var alertChevronView: UIImageView!
  
  @IBOutlet weak var expandyButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  private var disposeBag = DisposeBag()
  private let alertTapper = UITapGestureRecognizer()
  
  var alertTapped: Observable<Void> {
    alertTapper.rx.event
      .filter { $0.state == .recognized }
      .map { _ in }
  }
  
  static func newInstance() -> TKUIServiceHeaderView {
    return Bundle(for: TKUIServiceHeaderView.self).loadNibNamed("TKUIServiceHeaderView", owner: self, options: nil)?.first as! TKUIServiceHeaderView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    alertWrapper.addGestureRecognizer(alertTapper)
    
    backgroundColor = .tkBackground
    
    accessibilityTitleLabel.textColor = .tkLabelPrimary
    
    occupancyLabel.textColor = .tkLabelPrimary
    occupancyUpdatedLabel.textColor = .tkLabelSecondary

    // Same styling as in TKUISegmentAlertCell
    alertWrapper.layer.borderWidth = 1.0
    alertWrapper.layer.cornerRadius = 6.0
    if #available(iOS 13.0, *) {
      alertWrapper.backgroundColor = UIColor { _ in UIColor.tkStateWarning.withAlphaComponent(0.12) }
      alertWrapper.layer.borderColor = UIColor { traits in
        switch traits.userInterfaceStyle {
        case .dark: return UIColor.tkStateWarning.withAlphaComponent(0.3)
        default:    return UIColor.tkStateWarning.withAlphaComponent(0.6)
        }
      }.cgColor

    } else {
      alertWrapper.backgroundColor = UIColor.tkStateWarning.withAlphaComponent(0.12)
      alertWrapper.layer.borderColor = UIColor.tkStateWarning.withAlphaComponent(0.6).cgColor
    }
    
    alertImageView.tintColor = .tkStateWarning
    alertTitleLabel.textColor = .tkLabelPrimary
    alertBodyLabel.textColor = .tkLabelPrimary
    alertChevronView.tintColor = .tkLabelPrimary
    
    expandyButton.setImage(TGCard.arrowButtonImage(direction: .up, background: tintColor.withAlphaComponent(0.12), arrow: tintColor), for: .normal)
    expandyButton.setTitle(nil, for: .normal)
    expandyButton.accessibilityLabel = Loc.Collapse

    separator.backgroundColor = .tkLabelTertiary
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    
    expandyButton.setImage(TGCard.arrowButtonImage(direction: .up, background: tintColor.withAlphaComponent(0.12), arrow: tintColor), for: .normal)
  }
  
  private func updateAccessibility(_ accessibility: TKWheelchairAccessibility) {
    accessibilityImageView.image = accessibility.icon
    accessibilityTitleLabel.text = accessibility.title
  }
  
  private func updateRealTime(alerts: [Alert] = [], components: Observable<([[TKAPI.VehicleComponents]], Date)>?) {
    
    if let sampleAlert = alerts.first {
      alertWrapper.isHidden = false

      alertImageView.tintColor = sampleAlert.isCritical() ? .tkStateError : .tkStateWarning
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
    components?
      .subscribe(onNext: { [weak self] in
        self?.updateOccupancies($0.0, lastUpdated: $0.1)
      })
      .disposed(by: disposeBag)
  }
  
  private func updateOccupancies(_ components: [[TKAPI.VehicleComponents]], lastUpdated: Date) {
    
    Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
      .startWith(0)
      .subscribe(onNext: { [weak self] _ in
        let duration = Date.durationString(forSeconds: lastUpdated.timeIntervalSinceNow * -1)
        let updatedTitle = Loc.UpdatedAgo(duration: duration)
        self?.occupancyUpdatedLabel.text = Loc.LastUpdated(date: updatedTitle)
      })
      .disposed(by: disposeBag)

    if components.count > 1 || (components.first?.count ?? 0) > 1,
        let average = TKAPI.VehicleOccupancy.average(in: components) {
      occupancyWrapper.isHidden = false
      
      occupancyImageView.image = average.0.standingPeople()
      occupancyLabel.text = average.title

      trainOccupancyView.isHidden = false
      trainOccupancyView.occupancies = components.map { $0.map { $0.occupancy ?? .unknown } }
      trainOccupancyHeightConstraint?.isActive = true
      trainOccupancyBottomConstraint?.isActive = true
      
    } else if let component = components.first?.first, let occupancy = component.occupancy, occupancy != .unknown {
      occupancyWrapper.isHidden = false

      occupancyImageView.image = occupancy.standingPeople()
      occupancyLabel.text = component.occupancyText ?? occupancy.localizedTitle
      
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
    updateRealTime(alerts: model.alerts, components: model.vehicleComponents)
    
    // stack views are weird; this should be in the front, but sometimes
    // gets put back
    bringSubviewToFront(expandyButton)
    
    updateConstraintsIfNeeded()
  }
}
