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
  
  let titleView: TKUISegmentTitleView
  
  private let disposeBag = DisposeBag()
  
  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    titleView = TKUISegmentTitleView.newInstance()
    titleView.configure(for: segment)
    
    super.init(title: .custom(titleView, dismissButton: titleView.dismissButton), mapManager: mapManager)
  }
  
  required init?(coder: NSCoder) {
    // TODO: Implement to support state-restoration
    return nil
  }
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    guard let tableView = (cardView as? TGScrollCardView)?.tableView else { return }
    
    tableView.register(TKUITurnByTurnInstructionCell.nib, forCellReuseIdentifier: TKUITurnByTurnInstructionCell.reuseIdentifier)
    
    let shapes = segment.shortedShapes() ?? []
    
    Observable.just(shapes)
      .bind(to: tableView.rx.items) { (tableView, row, element) in
        let cell = tableView.dequeueReusableCell(withIdentifier: TKUITurnByTurnInstructionCell.reuseIdentifier, for: IndexPath(row: row, section: 0)) as! TKUITurnByTurnInstructionCell
        let cellContent = TKUITurnByTurnInstructionCell.ContentModel(mainInstruction: "\(element.title ?? "") - \(element.metres ?? 0)m")
        cell.content = cellContent        
        return cell
      }
      .disposed(by: disposeBag)
  }
  
}
