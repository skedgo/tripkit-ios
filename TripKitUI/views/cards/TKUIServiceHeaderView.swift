//
//  TKUIServiceHeaderView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUIServiceHeaderView: UIView {
  @IBOutlet weak var accessibilityWrapper: UIView!
  @IBOutlet weak var accessibilityImageView: UIImageView!
  @IBOutlet weak var accessibilityTitleLabel: UILabel!

  @IBOutlet weak var occupancyStack: UIStackView!
  @IBOutlet weak var occupancyImageView: UIImageView!
  @IBOutlet weak var occupancyLabel: UILabel!
  @IBOutlet weak var occupancyAdditionalStack: UIStackView!
  @IBOutlet weak var occupancyUpdatedLabel: UILabel!

  @IBOutlet weak var alertWrapper: UIView!
  @IBOutlet weak var alertImageView: UIImageView!
  @IBOutlet weak var alertTitleLabel: UILabel!
  @IBOutlet weak var alertBodyLabel: UILabel!
  @IBOutlet weak var alertMoreButton: UIButton!
  
  @IBOutlet weak var expandyButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  private let disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceHeaderView {
    return Bundle(for: TKUIServiceHeaderView.self).loadNibNamed("TKUIServiceHeaderView", owner: self, options: nil)?.first as! TKUIServiceHeaderView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    separator.backgroundColor = .tkLabelTertiary
    
    alertMoreButton.setTitle(Loc.ReadMore, for: .normal)
  }
  
  private func updateAccessibility(_ accessibility: TKUIWheelchairAccessibility? = nil) {
    accessibilityWrapper.isHidden = accessibility == nil
    accessibilityImageView.image = accessibility?.icon
    accessibilityTitleLabel.text = accessibility?.title
  }
  
  private func updateRealTime(alerts: [Alert] = [], occupancies: Observable<[[API.VehicleOccupancy]]>? = nil, lastUpdated: Date? = nil) {
    
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
    
    occupancyStack.isHidden = true
    occupancies?
      .subscribe(onNext: { [weak self] in self?.updateOccupancies($0) })
      .disposed(by: disposeBag)
    
    if let updated = lastUpdated {
      occupancyUpdatedLabel.isHidden = false
      #warning("TODO: Fix time zone, or use relative time (!) + 'ago'")
      occupancyUpdatedLabel.text = Loc.LastUpdated(date: TKStyleManager.string(for: updated, for: .autoupdatingCurrent, showDate: false, showTime: true))
    } else {
      occupancyUpdatedLabel.isHidden = true
    }
  }
  
  private func updateOccupancies(_ occupancies: [[API.VehicleOccupancy]]) {
    if occupancies.count > 1 || (occupancies.first?.count ?? 0) > 1 {
      occupancyStack.isHidden = false
      
      let average = API.VehicleOccupancy.average(in: occupancies.flatMap { $0 })
      occupancyImageView.image = average.standingPeople()
      occupancyLabel.text = average.localizedTitle

      let trainView = TKUITrainOccupancyView()
      trainView.occupancies = occupancies
      updateRealTimeInfoStackViewContent(with: trainView)
      
    } else if let occupancy = occupancies.first?.first, occupancy != .unknown {
      occupancyStack.isHidden = false

      occupancyImageView.image = occupancy.standingPeople()
      occupancyLabel.text = occupancy.localizedTitle
      
      updateRealTimeInfoStackViewContent(with: nil)

    } else {
      occupancyStack.isHidden = true
      updateRealTimeInfoStackViewContent(with: nil)
    }
  }
    
  private func updateRealTimeInfoStackViewContent(with newView: UIView?) {
    occupancyAdditionalStack.arrangedSubviews.forEach {
      occupancyAdditionalStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    if let newView = newView {
      occupancyAdditionalStack.addArrangedSubview(newView)
      occupancyAdditionalStack.isHidden = false
    } else {
      occupancyAdditionalStack.isHidden = true
    }
  }
}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceHeaderView {
  func configure(with model: TKUIDepartureCellContent) {
    updateAccessibility(model.wheelchairAccessibility)
    
    #warning("TODO: Add last updated")
    updateRealTime(alerts: model.alerts, occupancies: model.vehicleOccupancies, lastUpdated: Date())
  }
}
