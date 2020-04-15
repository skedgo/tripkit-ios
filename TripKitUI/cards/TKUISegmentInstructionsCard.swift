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
  
  let titleView: TKUISegmentTitleView
  let instructionView: TKUISegmentInstructionsView
  
  private let disposeBag = DisposeBag()

  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  public init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    titleView = TKUISegmentTitleView.newInstance()
    titleView.configure(for: segment)
    
    instructionView = TKUISegmentInstructionsView.newInstance()
    
    super.init(title: .custom(titleView, dismissButton: titleView.dismissButton), contentView: instructionView, mapManager: mapManager)
  }
  
  required init?(coder: NSCoder) {
    // LATER: Implement to support state-restoration
    return nil
  }
  
  public override func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    instructionView.notesLabel.text = segment.notes

    updateAccessoryViews(for: segment)
    
    // accessory views depend on real-time data, so let's update
    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: segment)
      .subscribe(onNext: { [weak self] _ in
        guard let segment = self?.segment else { return }
        self?.updateAccessoryViews(for: segment)
      })
      .disposed(by: disposeBag)
  }
  
  private func updateAccessoryViews(for segment: TKSegment) {
    guard let stack = instructionView.accessoryStackView else { return }
    
    stack.arrangedSubviews.forEach(stack.removeArrangedSubview)
    stack.removeAllSubviews()
    
    let accessoryViews = segment.buildAccessoryViews()
    accessoryViews.forEach(stack.addArrangedSubview)
  }
  
}
