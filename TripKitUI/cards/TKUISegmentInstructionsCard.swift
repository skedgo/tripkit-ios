//
//  TKUISegmentInstructionCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public class TKUISegmentInstructionCard: TGPlainCard {
  
  let segment: TKSegment
  
  let instructionView: TKUISegmentInstructionsView
  
  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  public init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    self.instructionView = TKUISegmentInstructionsView.newInstance()
    
    super.init(title: .default(segment.title ?? "", nil, nil), contentView: instructionView, mapManager: mapManager)
  }
  
  required init?(coder: NSCoder) {
    // TODO: Implement to support state-restoration
    return nil
  }
  
  override public func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    tripMapManager.show(segment, animated: animated)
  }
  
  public override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    instructionView.notesLabel.text = segment.notes
    
    let accessoryViews = segment.buildAccessoryViews()
    accessoryViews.forEach(instructionView.accessoryStackView.addArrangedSubview)
  }
  
}
