//
//  TKUISegmentTitleView+TKSegment.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

extension TKUISegmentTitleView {
  
  public enum SegmentMode {
    case getReady
    case onSegment
  }
  
  public func configure(for segment: TKSegment, mode: SegmentMode = .onSegment) {
    let title: String
    let subtitle: String?
    
    if segment.isPublicTransport, mode == .getReady,
      let destination = (segment.end?.title ?? nil),
      let origin = (segment.start?.title ?? nil) {
      // TODO: Localise
      title = "Get on service to \(destination)"
      subtitle = "From \(origin) "
      
    } else {
      title = segment.tripSegmentInstruction
      subtitle = segment.tripSegmentDetail
    }
    
    titleLabel.text = title
    subtitleLabel.text = subtitle
    
    modeIcon.setImage(with: segment.tripSegmentModeImageURL, asTemplate: segment.tripSegmentModeImageIsTemplate, placeholder: segment.tripSegmentModeImage)
  }
  
}
