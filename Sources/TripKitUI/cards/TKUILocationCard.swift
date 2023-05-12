//
//  TKUILocationCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 3/5/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController
import RxSwift
import RxCocoa

import TripKit

open class TKUILocationCard: TGTableCard {
  
  public static var config = Configuration.empty
  
  let location: TKNamedCoordinate
  
  let routeButton: TKUILocationInfo.RouteButton
  
  private var viewModel: TKUILocationViewModel!
  
  private var dataSource: UITableViewDiffableDataSource<TKUILocationViewModel.Section, TKUILocationViewModel.Item>!
  
  private let disposeBag = DisposeBag()
  
  public init(for location: TKNamedCoordinate, routeButton: TKUILocationInfo.RouteButton = .notAllowed) {
    self.location = location
    self.routeButton = routeButton
    
    let title = location.title ?? nil
    let subtitle = location.subtitle ?? nil
    
    super.init(
      title: .default(title ?? subtitle ?? Loc.Location),
      mapManager: TKUILocationMapManager(for: location),
      initialPosition: .peaking
    )
    
  }
  
  public override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    
    dataSource = UITableViewDiffableDataSource<TKUILocationViewModel.Section, TKUILocationViewModel.Item>(tableView: tableView) { tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
      cell.imageView?.image = item.image
      cell.imageView?.tintColor = .tkLabelPrimary
      cell.textLabel?.text = item.title
      cell.detailTextLabel?.text = item.subtitle
      return cell
    }
    
    viewModel = .init(for: location)
    
    viewModel.sections
      .drive(onNext: { [weak dataSource] sections in
        dataSource?.apply(Self.buildSnapshot(for: sections), animatingDifferences: true)
      })
      .disposed(by: disposeBag)
    
    var actions: [TKUILocationCard.Action] = []
    lazy var routeImage: UIImage = UIImage(systemName: "arrow.triangle.turn.up.right.diamond")?.withRenderingMode(.alwaysTemplate) ?? .iconAlternative
    switch routeButton {
    case .replace(let title, let onTap):
      actions.append(.init(title: title, icon: routeImage) { _, _, _, _ in
        onTap()
        return false
      })
    case .allowed:
      actions.append(.init(title: Loc.GetDirections, icon: routeImage) { [unowned self] _, _, _, _ in
        self.routeHere()
        return false
      })
    case .notAllowed:
      break
    }
    
    if let factory = Self.config.actionFactory {
      actions.append(contentsOf: factory(location))
    }
    
    if !actions.isEmpty {
      let actionsView = TKUICardActionsViewFactory.build(actions: actions, card: self, model: location, container: tableView, padding: .bottom)
      actionsView.frame.size.height = actionsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      tableView.tableHeaderView = actionsView
    } else {
      tableView.tableHeaderView = nil
    }
  }
  
  func routeHere() {
    controller?.push(TKUIRoutingResultsCard(destination: location))
  }
  
}

extension TKUILocationCard {
  static func buildSnapshot(for sections: [(TKUILocationViewModel.Section, [TKUILocationViewModel.Item])]) -> NSDiffableDataSourceSnapshot<TKUILocationViewModel.Section, TKUILocationViewModel.Item> {
    var snapshot = NSDiffableDataSourceSnapshot<TKUILocationViewModel.Section, TKUILocationViewModel.Item>()
    snapshot.appendSections(sections.map(\.0))
    for (section, items) in sections {
      snapshot.appendItems(items, toSection: section)
    }
    return snapshot
  }
}
