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
  @IBOutlet weak var accessibilityStack: UIStackView!
  @IBOutlet weak var accessibilityImageView: UIImageView!
  @IBOutlet weak var accessibilityTitleLabel: UILabel!

  @IBOutlet weak var realTimeStack: UIStackView!
  @IBOutlet weak var realTimeImageView: UIImageView!
  @IBOutlet weak var realTimeAlertStack: UIStackView!
  @IBOutlet weak var realTimeAlertImageView: UIImageView!
  @IBOutlet weak var realTimeAlertLabel: UILabel!
  @IBOutlet weak var realTimeInfoStack: UIStackView!
  @IBOutlet weak var realTimeUpdatedLabel: UILabel!

  @IBOutlet weak var infoStack: UIStackView!
  
  @IBOutlet weak var expandyButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  private let disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceHeaderView {
    return Bundle(for: TKUIServiceHeaderView.self).loadNibNamed("TKUIServiceHeaderView", owner: self, options: nil)?.first as! TKUIServiceHeaderView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    updateAccessibility()
    updateRealTime()

    infoStack.isHidden = true
    
    separator.backgroundColor = .tkLabelTertiary
  }
  
  private func updateAccessibility(_ accessibility: TKUIWheelchairAccessibility? = nil) {
    accessibilityStack.isHidden = accessibility == nil
    accessibilityImageView.image = accessibility?.icon
    accessibilityTitleLabel.text = accessibility?.title
  }
  
  private func updateRealTime(alerts: [Alert] = [], occupancies: Observable<[[API.VehicleOccupancy]]>? = nil, lastUpdated: Date? = nil) {
    
    // TODO: Show alerts
    
    occupancies?.subscribe(onNext: { [weak self] occupancies in
        if occupancies.count > 1 || (occupancies.first?.count ?? 0) > 1 {
          let trainView = TKUITrainOccupancyView()
          trainView.occupancies = occupancies
          self?.updateRealTimeInfoStackViewContent(with: trainView)
        } else if let occupancy = occupancies.first?.first, occupancy != .unknown {
          let occupancyView = TKUIOccupancyView(with: .occupancy(occupancy))
          self?.updateRealTimeInfoStackViewContent(with: occupancyView)
        } else {
          self?.updateRealTimeInfoStackViewContent(with: nil)
        }
      })
      .disposed(by: disposeBag)
    
    if let updated = lastUpdated {
      realTimeUpdatedLabel.isHidden = false
      realTimeUpdatedLabel.text = Loc.LastUpdated(date: TKStyleManager.string(for: updated, for: .autoupdatingCurrent, showDate: false, showTime: true))
    } else {
      realTimeUpdatedLabel.isHidden = true
    }
  }
    
  private func updateRealTimeInfoStackViewContent(with newView: UIView?) {
    realTimeInfoStack.arrangedSubviews.forEach {
      realTimeInfoStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    if let newView = newView {
      realTimeInfoStack.addArrangedSubview(newView)
      realTimeInfoStack.isHidden = false
    } else {
      realTimeInfoStack.isHidden = true
    }
  }
}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceHeaderView {
  func configure(with model: TKUIDepartureCellContent) {
    updateAccessibility(model.wheelchairAccessibility)
    updateRealTime(alerts: model.alerts, occupancies: model.vehicleOccupancies, lastUpdated: Date())
  }
}
