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
  
  public func configure(for segment: TKSegment, preferredTitle: String? = nil, mode: TKUISegmentMode = .onSegment) {
    update(for: segment, preferredTitle: preferredTitle, mode: mode)
    monitorUpdates(for: segment, preferredTitle: preferredTitle, mode: mode)
  }
  
  private func update(for segment: TKSegment, preferredTitle: String?, mode: TKUISegmentMode) {
    let title: String
    let subtitle: String?
    
    if segment.isPublicTransport, mode == .getReady,
      let destination = (segment.finalSegmentIncludingContinuation().end?.title ?? nil),
      let origin = (segment.start?.title ?? nil) {
      title = Loc.GetOnService(To: destination)
      subtitle = Loc.From(location: origin)
      
    } else {
      title = preferredTitle ?? segment.tripSegmentInstruction
      subtitle = segment.tripSegmentDetail
    }
    
    titleLabel.text = title
    subtitleLabel.text = subtitle
    
    modeWrapper.backgroundColor = .tkStateSuccess
    modeWrapper.layer.borderWidth = 2
    modeWrapper.layer.borderColor = UIColor.tkStateSuccess.cgColor
    modeIcon.setImage(with: segment.tripSegmentModeImageURL, asTemplate: segment.tripSegmentModeImageIsTemplate, placeholder: segment.tripSegmentModeImage) { [weak self] success in
      guard
        let self = self,
        success,
        segment.tripSegmentModeImageIsBranding
        else { return }

      self.modeWrapper.backgroundColor = .tkBackground
    }
  }
  
  private func monitorUpdates(for segment: TKSegment, preferredTitle: String?, mode: TKUISegmentMode) {
    disposeBag = DisposeBag()
    
    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: segment)
      .subscribe(onNext: { [weak self] _ in
        self?.update(for: segment, preferredTitle: preferredTitle, mode: mode)
      })
      .disposed(by: disposeBag)    
  }
  
}
