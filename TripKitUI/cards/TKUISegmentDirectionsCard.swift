//
//  TKUISegmentDirectionsCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

import RxSwift
import RxCocoa

public class TKUISegmentDirectionsCard: TGTableCard {
  
  let segment: TKSegment
  
  let titleView: TKUISegmentHeaderView
  
  private let disposeBag = DisposeBag()
  
  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    titleView = TKUISegmentHeaderView.newInstance()
    titleView.configure(for: segment)
    
    super.init(title: .custom(titleView, dismissButton: titleView.dismissButton), mapManager: mapManager)
  }
  
  required init?(coder: NSCoder) {
    // TODO: Implement to support state-restoration
    return nil
  }
  
  override public func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    tripMapManager.show(segment, animated: animated)
  }
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    guard let tableView = (cardView as? TGScrollCardView)?.tableView else { return }
    
    let shapes = segment.shortedShapes() ?? []
    
    Observable.just(shapes)
      .bind(to: tableView.rx.items) { (tableView, row, element) in
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = "\(element.title ?? "") - \(element.metres ?? 0)m"
        return cell
      }
      .disposed(by: disposeBag)
  }
  
}
