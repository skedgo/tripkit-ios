//
//  TKUITripOverviewCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import TGCardViewController

#if TK_NO_MODULE
#else
  import TripKit
#endif


public class TKUITripsPageCard: TGPageCard {
  
  /// Constructs a page card configured for displaying the alternative trips
  /// of a request.
  ///
  /// - Parameter trip: Trip to focus on first
  public init(highlighting trip: Trip) {
    // make sure this is the visible trip in our group
    trip.setAsPreferredTrip()
    
    let trips = trip.request.sortedVisibleTrips()
    guard let index = trips.firstIndex(of: trip) else { preconditionFailure() }
    
    let cards = trips.enumerated().map { TKUITripOverviewCard(trip: $1, index: $0) }
    
    super.init(cards: cards, initialPage: index, includeHeader: false)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

public class TKUITripOverviewCard: TGTableCard {
  
  public static var config = Configuration.empty
  
  private let index: Int? // for restoring
  private var zoomToTrip: Bool = false // for restoring
  
  fileprivate let viewModel: TKUITripOverviewViewModel
  private let disposeBag = DisposeBag()
  
  public init(trip: Trip, index: Int? = nil) {
    viewModel = TKUITripOverviewViewModel(trip: trip)
    self.index = index
    
    let mapManager = TKUITripOverviewCard.config.mapManagerFactory(trip)
    super.init(title: Loc.Trip(index: index.map { $0 + 1 }), mapManager: mapManager)
  }
  
  public required convenience init?(coder: NSCoder) {
    guard
      let data = coder.decodeObject(forKey: "viewModel") as? Data,
      let trip = TKUITripOverviewViewModel.restore(from: data)
      else {
        return nil
    }
    
    let index = coder.containsValue(forKey: "index")
      ? coder.decodeInteger(forKey: "index")
      : nil
    
    self.init(trip: trip, index: index)

    zoomToTrip = true
  }
  
  public override func encode(with aCoder: NSCoder) {
    aCoder.encode(TKUITripOverviewViewModel.save(trip: viewModel.trip), forKey: "viewModel")

    if let index = index {
      aCoder.encode(index, forKey: "index")
    }
  }

  override public func didBuild(tableView: UITableView, cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(tableView: tableView, cardView: cardView, headerView: headerView)
    
    tableView.register(TKUISegmentStationaryCell.nib, forCellReuseIdentifier: TKUISegmentStationaryCell.reuseIdentifier)
    tableView.register(TKUISegmentMovingCell.nib, forCellReuseIdentifier: TKUISegmentMovingCell.reuseIdentifier)
    tableView.register(TKUISegmentAlertCell.nib, forCellReuseIdentifier: TKUISegmentAlertCell.reuseIdentifier)

    tableView.dataSource = nil
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUITripOverviewViewModel.Section>(
      configureCell: { [unowned self] ds, tv, ip, item in
        switch item {
        case .terminal(let item):
          return TKUITripOverviewCard.terminalCell(for: item, tableView: tv, indexPath: ip)
        case .stationary(let item):
          return TKUITripOverviewCard.stationaryCell(for: item, tableView: tv, indexPath: ip)
        case .moving(let item):
          return self.movingCell(for: item, tableView: tv, indexPath: ip)
        case .alert(let item):
          return self.alertCell(for: item, tableView: tv, indexPath: ip)
        }
    })
    
    viewModel.titles
      .drive(cardView.rx.titles)
      .disposed(by: disposeBag)

    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.dataSources
      .drive(onNext: { sources in
        self.showAttribution(for: sources, in: tableView)
      })
      .disposed(by: disposeBag)
    
    viewModel.refreshMap
      .emit(onNext: {
        (self.mapManager as? TKUITripMapManager)?.updateTrip()
      })
      .disposed(by: disposeBag)
    
    if let factory = TKUITripOverviewCard.config.tripActionsFactory {
      let actions = factory(viewModel.trip)
      let actionsView = TKUITripActionsView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80))
      actionsView.configure(with: actions, for: viewModel.trip, card: self)
      tableView.tableHeaderView = actionsView
    } else {
      tableView.tableHeaderView = nil
    }

    // Handling segment selections
    if let segmentHandler = TKUITripOverviewCard.config.presentSegmentHandler {
      tableView.rx.itemSelected
        .filter { !dataSource[$0].isAlert }
        .map { (self, self.viewModel.segment(for: dataSource[$0])) }
        .filter { $1 != nil }
        .map { ($0, $1!) }
        .subscribe(onNext: segmentHandler)
        .disposed(by: disposeBag)
    }
    
    // Handling action on alerts
    tableView.rx.itemSelected
      .map {
        switch dataSource[$0] {
        case .alert(let alertItem): return alertItem.alerts as [TKAlert]
        default: return []
        }
      }
      .filter { !$0.isEmpty }
      .subscribe(onNext: show)
      .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
   
    TKUICustomization.shared.feedbackActiveItemHandler?(viewModel.trip)
    
    if zoomToTrip {
      (mapManager as? TKUITripMapManager)?.showTrip(animated: animated)
      zoomToTrip = false
    } else {
      (mapManager as? TKUITripMapManager)?.deselectSegment(animated: animated)
    }
  }
  
}

// MARK: - Configuring cells

extension TKUITripOverviewCard {
  
  private static func terminalCell(for terminal: TKUITripOverviewViewModel.TerminalItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentStationaryCell.reuseIdentifier, for: indexPath) as? TKUISegmentStationaryCell else { preconditionFailure() }
    cell.configure(with: terminal)
    return cell
  }

  private static func stationaryCell(for stationary: TKUITripOverviewViewModel.StationaryItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentStationaryCell.reuseIdentifier, for: indexPath) as? TKUISegmentStationaryCell else { preconditionFailure() }
    cell.configure(with: stationary)
    return cell
  }
  
  private func alertCell(for alertItem: TKUITripOverviewViewModel.AlertItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentAlertCell.reuseIdentifier, for: indexPath) as? TKUISegmentAlertCell else { preconditionFailure() }
    cell.configure(with: alertItem)    
    return cell
  }

  private func movingCell(for moving: TKUITripOverviewViewModel.MovingItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentMovingCell.reuseIdentifier, for: indexPath) as? TKUISegmentMovingCell else { preconditionFailure() }
    cell.configure(with: moving, for: self)
    return cell
  }

}

// MARK: - Attribution

extension TKUITripOverviewCard {
  private func showAttribution(for sources: [API.DataAttribution], in tableView: UITableView) {
    let footer = TKUIAttributionView.newView(sources, fitsIn: tableView)
    footer?.backgroundColor = tableView.backgroundColor
    
    let tapper = UITapGestureRecognizer(target: nil, action: nil)
    tapper.rx.event
      .filter { $0.state == .ended }
      .subscribe(onNext: { [weak self] _ in
        self?.presentAttributions(for: sources, sender: footer)
      })
      .disposed(by: disposeBag)
    footer?.addGestureRecognizer(tapper)
    
    tableView.tableFooterView = footer
  }
  
  private func presentAttributions(for sources: [API.DataAttribution], sender: Any?) {
    
    let attributor = TKUIAttributionTableViewController(attributions: sources)
    attributor.delegate = self
    
    let navigator = UINavigationController(rootViewController: attributor)
    present(navigator, sender: sender)
  }
  
  private func present(_ viewController: UIViewController, sender: Any? = nil) {
    guard let controller = controller else { return }
    if controller.traitCollection.horizontalSizeClass == .regular {
      viewController.modalPresentationStyle = .popover
      let presentation = viewController.popoverPresentationController
      presentation?.sourceView = controller.view
      if let view = sender as? UIView {
        presentation?.sourceView = view
        presentation?.sourceRect = view.bounds
      } else if let barButton = sender as? UIBarButtonItem {
        presentation?.barButtonItem = barButton
      }
    } else {
      viewController.modalPresentationStyle = .currentContext
    }
    controller.present(viewController, animated: true)
  }
  
}

// MARK: TKUIAttributionTableViewControllerDelegate

extension TKUITripOverviewCard: TKUIAttributionTableViewControllerDelegate {
  
  public func attributor(_ attributor: TKUIAttributionTableViewController, requestsWebsite url: URL) {
    TKUITripOverviewCard.config.presentAttributionHandler?(self, attributor, url)
  }
  
  public func requestsDismissal(attributor: TKUIAttributionTableViewController) {
    attributor.presentingViewController?.dismiss(animated: true)
  }
  
}

// MARK: - Navigation

extension TKUITripOverviewCard {
  
  private func show(_ alerts: [TKAlert]) {
    let alertController = TKUIAlertViewController()
    alertController.alerts = alerts
    controller?.present(alertController, inNavigator: true)
  }
  
}
