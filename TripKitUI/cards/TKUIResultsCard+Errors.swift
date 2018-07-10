//
//  TKUIResultsCard+Errors.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift
import RxCocoa

extension TKUIResultsCard {
  
  func show(_ error: Error, for request: TripRequest, cardView: TGCardView, tableView: UITableView) {
    guard let controller = controller, viewIsVisible
      else { return }
    
    if (error as NSError).code == 1001 {
      let parent = (cardView as? TGScrollCardView)?.scrollViewWrapper ?? cardView
      showRoutingSupportView(with: error, for: request, parentView: parent, tableView: tableView)
    } else {
      TKUICustomization.shared.alertHandler?(error, controller)
    }
  }
  
  func clearError(in cardView: TGCardView) {
    let parent = (cardView as? TGScrollCardView)?.scrollViewWrapper ?? cardView
    TKUIRoutingSupportView.clear(from: parent)
  }
  
  private func showRoutingSupportView(with error: Error, for request: TripRequest, parentView: UIView, tableView: UITableView) {
    let supportView = TKUIRoutingSupportView.show(with: error, for: request, in: parentView, aboveSubview: tableView)
    
    supportView.requestSupportButton.isHidden = (TKUIResultsCard.config.requestRoutingSupport == nil)
    supportView.requestSupportButton.rx.tap
      .subscribe(onNext: { [unowned self] in
        TKUIResultsCard.config.requestRoutingSupport?(self, request)
      })
      .disposed(by: disposeBag)
    
    // Can plan trip right from results card, no need to have a button
    supportView.planNewTripButton.isHidden = true
  }
  
}
