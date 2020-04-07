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
  
  typealias SegmentActionsView = TKUICardActionsView<TKUISegmentDirectionsCard, TKSegment>
  
  public static func canShowInstructions(for segment: TKSegment) -> Bool {
    return TKUISegmentDirectionsViewModel.canShowInstructions(for: segment)
  }
  
  public static var config = Configuration.empty
  
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
  
  override public func didBuild(tableView: UITableView, headerView: TGHeaderView?) {
    super.didBuild(tableView: tableView, headerView: headerView)

    viewModel = TKUISegmentDirectionsViewModel(segment: segment)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUISegmentDirectionsViewModel.Section>(configureCell: TKUISegmentDirectionsCard.configureCell)
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    if let factory = Self.config.actionFactory {
      let actions = factory(segment)
      let actionsView = SegmentActionsView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 0))
      actionsView.configure(with: actions, model: segment, card: self)
      actionsView.frame.size.height = actionsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      tableView.tableHeaderView = actionsView
    } else {
      tableView.tableHeaderView = nil
    }
  }
  
  private func setup(_ tableView: UITableView) {
    tableView.tableFooterView = UIView()
  }
  
}

// MARK: Configuring cells

extension TKUISegmentDirectionsCard {
  
  static func configureCell(dataSource: TableViewSectionedDataSource<TKUISegmentDirectionsViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUISegmentDirectionsViewModel.Item) -> UITableViewCell {

    let identifier = "TurnByTurnInstructionCell"
    let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)

    cell.backgroundColor = .tkBackground
    cell.imageView?.image = item.image
    cell.textLabel?.textColor = .tkLabelPrimary

    if let distance = item.distance {
      let distanceFormatter = MKDistanceFormatter()
      distanceFormatter.unitStyle = .abbreviated
      
      cell.textLabel?.text = distanceFormatter.string(fromDistance: distance)
    }
    
    cell.detailTextLabel?.textColor = .tkLabelSecondary
    cell.detailTextLabel?.text = item.streetInstruction
    
    return cell
  }
  
}
