//
//  TKUISegmentInstructionCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

public class TKUISegmentInstructionCard: TGPlainCard {

  let segment: TKSegment
  
  let titleView: TKUISegmentTitleView
  let instructionView: TKUISegmentInstructionsView
  
  private let disposeBag = DisposeBag()

  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  public static func hasContent(for segment: TKSegment) -> Bool {
    (segment.notes ?? "").isEmpty == false
  }
  
  public init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    titleView = TKUISegmentTitleView.newInstance()
    titleView.configure(for: segment)
    
    instructionView = TKUISegmentInstructionsView.newInstance()
    
    super.init(title: .custom(titleView, dismissButton: titleView.dismissButton), contentView: instructionView, mapManager: mapManager)
    
    titleView.applyStyleToCloseButton(style)
  }
  
  public override func didBuild(cardView: TGCardView?, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    instructionView.notesLabel.text = segment.notes

    updateAccessoryViews(for: segment)
    
    // accessory views depend on real-time data, so let's update
    NotificationCenter.default.rx
      .notification(.TKUIUpdatedRealTimeData, object: segment)
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] _ in
        guard let segment = self?.segment else { return }
        self?.updateAccessoryViews(for: segment)
      })
      .disposed(by: disposeBag)
  }
  
  private func updateAccessoryViews(for segment: TKSegment) {
    guard let stack = instructionView.accessoryStackView else { return }
    
    stack.arrangedSubviews.forEach(stack.removeArrangedSubview)
    stack.subviews.forEach { $0.removeFromSuperview() }
    
    let accessoryViews = segment.buildAccessoryViews()
    accessoryViews.forEach(stack.addArrangedSubview)
  }
  
}
