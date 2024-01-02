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
  
  public func configure(for segment: TKSegment, preferredTitle: String? = nil, showSubtitle: Bool = true, mode: TKUISegmentMode = .onSegment) {
    update(for: segment, preferredTitle: preferredTitle, showSubtitle: showSubtitle, mode: mode)
    monitorUpdates(for: segment, preferredTitle: preferredTitle, showSubtitle: showSubtitle, mode: mode)
  }
  
  private func update(for segment: TKSegment, preferredTitle: String?, showSubtitle: Bool, mode: TKUISegmentMode) {
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
    subtitleLabel.text = showSubtitle ? subtitle : nil
    
    modeWrapper.backgroundColor = .clear
    modeWrapper.layer.borderWidth = 2
    modeWrapper.layer.borderColor = UIColor.tkNeutral3.cgColor 
    modeIcon.setImage(with: segment.tripSegmentModeImageURL, asTemplate: segment.tripSegmentModeImageIsTemplate, placeholder: segment.tripSegmentModeImage) { [weak self] success in
      guard
        let self = self,
        success,
        segment.tripSegmentModeImageIsBranding
        else { return }

      self.modeWrapper.backgroundColor = .white
    }
  }
  
  private func monitorUpdates(for segment: TKSegment, preferredTitle: String?, showSubtitle: Bool, mode: TKUISegmentMode) {
    disposeBag = DisposeBag()
    
    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: segment)
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        self?.update(for: segment, preferredTitle: preferredTitle, showSubtitle: showSubtitle, mode: mode)
      })
      .disposed(by: disposeBag)    
  }
  
}
