//
//  TKUISegmentInstructionCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

import RxSwift
import RxCocoa

public class TKUISegmentInstructionCard: TGPlainCard {
  
  let segment: TKSegment
  
  let titleView: TKUISegmentHeaderView
  let instructionView: TKUISegmentInstructionsView
  
  private let disposeBag = DisposeBag()

  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  public init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    titleView = TKUISegmentHeaderView.newInstance()
    titleView.configure(for: segment)
    
    instructionView = TKUISegmentInstructionsView.newInstance()
    
    super.init(title: .custom(titleView, dismissButton: titleView.dismissButton), contentView: instructionView, mapManager: mapManager)
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
