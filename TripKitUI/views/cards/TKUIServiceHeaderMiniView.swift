//
//  TKUIServiceHeaderMiniView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31.07.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUIServiceHeaderMiniView: UIView {
  @IBOutlet weak var collapsedAccessibilityImageView: UIImageView!
  
  @IBOutlet weak var expandyButton: UIButton!
  @IBOutlet weak var separator: UIView!
  
  private let disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIServiceHeaderMiniView {
    return Bundle(for: TKUIServiceHeaderMiniView.self).loadNibNamed("TKUIServiceHeaderMiniView", owner: self, options: nil)?.first as! TKUIServiceHeaderMiniView
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    updateAccessibility()
    updateRealTime()
    
    separator.backgroundColor = .tkLabelTertiary
  }
  
  private func updateAccessibility(_ accessibility: TKUIWheelchairAccessibility? = nil) {
    collapsedAccessibilityImageView.image = accessibility?.icon
    collapsedAccessibilityImageView.isHidden = accessibility == nil
  }
  
  private func updateRealTime(alerts: [Alert] = [], occupancies: Observable<[[API.VehicleOccupancy]]>? = nil, lastUpdated: Date? = nil) {
    
    // TODO: Show alert + occupancy icons
  }
}

// MARK: - TKUIDepartureCellContent compatibility

extension TKUIServiceHeaderMiniView {
  func configure(with model: TKUIDepartureCellContent) {
    updateAccessibility(model.wheelchairAccessibility)
    updateRealTime(alerts: model.alerts, occupancies: model.vehicleOccupancies, lastUpdated: Date())
  }
}
