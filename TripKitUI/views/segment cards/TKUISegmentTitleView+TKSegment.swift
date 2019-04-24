//
//  TKUISegmentTitleView+TKSegment.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TripKit

extension TKUISegmentTitleView {
  
  public func configure(for segment: TKSegment, mode: TKUISegmentMode = .onSegment) {
    update(for: segment, mode: mode)
    
    monitorUpdates(for: segment, mode: mode)
  }
  
  private func update(for segment: TKSegment, mode: TKUISegmentMode) {
    let title: String
    let subtitle: String?
    
    if segment.isPublicTransport, mode == .getReady,
      let destination = (segment.end?.title ?? nil),
      let origin = (segment.start?.title ?? nil) {
      // TODO: Localise
      title = "Get on service to \(destination)"
      subtitle = Loc.From(location: origin)
      
    } else {
      title = segment.tripSegmentInstruction
      subtitle = segment.tripSegmentDetail
    }
    
    titleLabel.text = title
    subtitleLabel.text = subtitle
    
    modeIcon.setImage(with: segment.tripSegmentModeImageURL, asTemplate: segment.tripSegmentModeImageIsTemplate, placeholder: segment.tripSegmentModeImage)
  }
  
  private func monitorUpdates(for segment: TKSegment, mode: TKUISegmentMode) {
    disposeBag = DisposeBag()
    
    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: segment)
      .subscribe(onNext: { [weak self] _ in
        self?.update(for: segment, mode: mode)
      })
      .disposed(by: disposeBag)
    
  }
  
}
