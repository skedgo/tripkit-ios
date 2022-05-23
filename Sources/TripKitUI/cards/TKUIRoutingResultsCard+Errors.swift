//
//  TKUIRoutingResultsCard+Errors.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 09.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import TGCardViewController
import RxSwift
import RxCocoa

import TripKit

extension TKUIRoutingResultsCard {
  
  func show(
      _ error: Error,
      for request: TripRequest?,
      cardView: TGCardView,
      tableView: UITableView
    ) -> UIView {

    let parent = (cardView as? TGScrollCardView)?.scrollViewWrapper ?? cardView

    switch ((error as NSError).code, request) {
    case (1001...1003, .some(let request)):
      return showRoutingSupportView(with: error, for: request, parentView: parent, tableView: tableView)
    default:
      return showErrorView(with: error, for: request, parentView: parent, tableView: tableView)
    }
  }
  
  func clear(_ errorView: UIView) {
    errorView.removeFromSuperview()
  }
  
  private func showRoutingSupportView(
      with error: Error,
      for request: TripRequest,
      parentView: UIView,
      tableView: UITableView
  ) -> TKUIRoutingSupportView {
    
    let allowRequest = TKUIRoutingResultsCard.config.contactCustomerSupport != nil

    let supportView = TKUIRoutingSupportView.show(
      with: error,
      for: request,
      in: parentView,
      aboveSubview: tableView,
      topPadding: tableView.tableHeaderView?.frame.height ?? 0,
      allowRequest: allowRequest
    )
    
    if allowRequest {
      supportView.requestSupportButton.rx.tap
        .subscribe(onNext: { [unowned self] in
          TKUIRoutingResultsCard.config.contactCustomerSupport?(self, .unsupportedQuery(request))
        })
        .disposed(by: disposeBag)
    }
    
    // Can plan trip right from results card, no need to have a button
    supportView.planNewTripButton.isHidden = true
    
    return supportView
  }
  
  private func showErrorView(
    with error: Error,
    for request: TripRequest?,
    parentView: UIView,
    tableView: UITableView
  ) -> TKUITripBoyView {
    let allowRequest = TKUIRoutingResultsCard.config.contactCustomerSupport != nil
    let actionTitle = allowRequest ? Loc.ContactSupport : nil

    let tripBoy = TKUITripBoyView.show(
      error: error,
      title: "Trips not available".localizedCapitalized,
      in: parentView,
      aboveSubview: tableView,
      topPadding: tableView.tableHeaderView?.frame.height ?? 0,
      actionTitle: actionTitle
    )

    if let request = request, allowRequest {
      tripBoy.actionButton.rx.tap
        .subscribe(onNext: { [unowned self] in
          TKUIRoutingResultsCard.config.contactCustomerSupport?(self, .routingError(error, request))
        })
        .disposed(by: disposeBag)
    }
    
    return tripBoy
  }
  
}
