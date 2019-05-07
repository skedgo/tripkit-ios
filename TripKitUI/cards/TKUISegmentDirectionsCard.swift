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
import RxDataSources

public class TKUISegmentDirectionsCard: TGTableCard {
  
  public static func canShowInstructions(for segment: TKSegment) -> Bool {
    return TKUISegmentDirectionsViewModel.canShowInstructions(for: segment)
  }
  
  let segment: TKSegment
  
  let titleView: TKUISegmentTitleView
  
  private var viewModel: TKUISegmentDirectionsViewModel!
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
    // LATER: Implement to support state-restoration
    return nil
  }
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    guard let tableView = (cardView as? TGScrollCardView)?.tableView else { return }
    
    tableView.register(TKUITurnByTurnInstructionCell.nib, forCellReuseIdentifier: TKUITurnByTurnInstructionCell.reuseIdentifier)
    
    viewModel = TKUISegmentDirectionsViewModel(segment: segment)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUISegmentDirectionsViewModel.Section>( configureCell: { (ds, tv, ip, item) -> UITableViewCell in
      let cell = tableView.dequeueReusableCell(withIdentifier: TKUITurnByTurnInstructionCell.reuseIdentifier, for: ip) as! TKUITurnByTurnInstructionCell
      cell.content = item.contentModel
      return cell
    })
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
  }
  
}

extension TKUISegmentDirectionsViewModel.Item {
  
  var contentModel: TKUITurnByTurnInstructionCell.ContentModel {
    return TKUITurnByTurnInstructionCell.ContentModel(mainInstruction: mainInstruction, supplementalInfo: supplementalInfo, directionImage: directionImage)
  }
  
}
