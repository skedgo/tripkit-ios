//
//  TKUIServiceHeaderMiniView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift
import TGCardViewController

class TKUIServiceHeaderMiniView: UIView {
  @IBOutlet weak var accessibilityImageView: UIImageView!
  @IBOutlet weak var occupancyImageView: UIImageView!
  @IBOutlet weak var alertImageView: UIImageView!
  
  @IBOutlet weak var expandyButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  private var disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceHeaderMiniView {
    return Bundle(for: TKUIServiceHeaderMiniView.self).loadNibNamed("TKUIServiceHeaderMiniView", owner: self, options: nil)?.first as! TKUIServiceHeaderMiniView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    expandyButton.setImage(TGCard.arrowButtonImage(direction: .down, background: tintColor.withAlphaComponent(0.12), arrow: tintColor), for: .normal)
    expandyButton.setTitle(nil, for: .normal)
    expandyButton.accessibilityLabel = Loc.Expand

    separator.backgroundColor = .tkLabelTertiary
  }
  
  override func tintColorDidChange() {
    super.tintColorDidChange()
    
    expandyButton.setImage(TGCard.arrowButtonImage(direction: .down, background: tintColor.withAlphaComponent(0.12), arrow: tintColor), for: .normal)
  }
  
  private func updateAccessibility(_ accessibility: TKUIWheelchairAccessibility) {
    accessibilityImageView.image = accessibility.icon
  }
  
  private func updateRealTime(alerts: [Alert] = [], occupancies: Observable<[[API.VehicleOccupancy]]>? = nil) {
    
    let alert = alerts.first
    alertImageView.isHidden = alert == nil
    alertImageView.image = alert?.icon
    alertImageView.accessibilityLabel = alert?.title ?? Loc.Alert

    occupancyImageView.isHidden = true
    occupancies?
      .subscribe(onNext: { [weak self] in
        let average = API.VehicleOccupancy.average(in: $0.flatMap { $0 })
        self?.occupancyImageView.isHidden = average == nil
        self?.occupancyImageView.image = average?.standingPeople()
        self?.occupancyImageView.accessibilityLabel = average?.localizedTitle
      })
      .disposed(by: disposeBag)
  }
}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceHeaderMiniView {
  func configure(with model: TKUIDepartureCellContent) {
    disposeBag = DisposeBag()

    updateAccessibility(model.wheelchairAccessibility)
    updateRealTime(alerts: model.alerts, occupancies: model.vehicleOccupancies?.map { $0.0 })
    
    // stack views are weird; this should be in the front, but sometimes
    // gets put back
    bringSubviewToFront(expandyButton)
  }
}
