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

extension TGPageCard {
  
  /// Constructs a page card configured for displaying the alternative trips
  /// of a request.
  ///
  /// - Parameter trip: Trip to focus on first
  public convenience init(overviewsHighlighting trip: Trip) {
    // make sure this is the visible trip in our group
    trip.setAsPreferredTrip()
    
    let trips = trip.request.sortedVisibleTrips()
    guard let index = trips.index(of: trip) else { preconditionFailure() }
    
    let cards = trips.enumerated().map { TKUITripOverviewCard(trip: $1, index: $0) }
    
    self.init(cards: cards, initialPage: index)
    
    if let tripHandler = TKUITripOverviewCard.config.startTripHandler {
      // TODO: Localize
      headerRightAction = (title: "Start", onPress: { index in
        let card = cards[index]
        let trip = card.viewModel.trip
        tripHandler(card, trip)
      })
    }
  }
  
}


public class TKUITripOverviewCard: TGTableCard {
  
  public static var config = Configuration.empty
  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUITripOverviewViewModel.Section>(
    configureCell: { ds, tv, ip, item in
      switch item {
      case .terminal(let item):
        return TKUITripOverviewCard.terminalCell(for: item, tableView: tv, indexPath: ip)
      case .stationary(let item):
        return TKUITripOverviewCard.stationaryCell(for: item, tableView: tv, indexPath: ip)
      case .moving(let item):
        return TKUITripOverviewCard.movingCell(for: item, tableView: tv, indexPath: ip)
      }
    }
  )
  
  fileprivate let viewModel: TKUITripOverviewViewModel
  private let disposeBag = DisposeBag()
  
  public init(trip: Trip, index: Int? = nil) {
    viewModel = TKUITripOverviewViewModel(trip: trip)
    
    let mapManager = TKUITripMapManager(trip: trip)
    
    // TODO: Localize
    let title: String
    if let index = index {
      title = "Trip \(index + 1)"
    } else {
      title = "Trip"
    }
    
    super.init(title: title, dataSource: dataSource, mapManager: mapManager)
  }
  
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard let tableView = (cardView as? TGScrollCardView)?.tableView else {
      preconditionFailure()
    }
    
    tableView.register(TKUISegmentStationaryCell.nib, forCellReuseIdentifier: TKUISegmentStationaryCell.reuseIdentifier)
    tableView.register(TKUISegmentMovingCell.nib, forCellReuseIdentifier: TKUISegmentMovingCell.reuseIdentifier)

    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    tableView.dataSource = nil
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.dataSources
      .drive(onNext: { sources in
        self.showAttribution(for: sources, in: tableView)
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
        .map { (self, self.viewModel.segment(for: self.dataSource[$0])) }
        .filter { $1 != nil }
        .map { ($0, $1!)}
        .subscribe(onNext: segmentHandler)
        .disposed(by: disposeBag)
    }
  }
  
  
  override public func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
   
    TKUICustomization.shared.feedbackActiveItemHandler?(viewModel.trip)
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

  private static func movingCell(for moving: TKUITripOverviewViewModel.MovingItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentMovingCell.reuseIdentifier, for: indexPath) as? TKUISegmentMovingCell else { preconditionFailure() }
    cell.configure(with: moving)
    return cell
  }

}

// MARK: - Attribution

extension TKUITripOverviewCard {
  private func showAttribution(for sources: [API.DataAttribution], in  tableView: UITableView) {
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
    controller.present(viewController, animated: true, completion: nil)
  }
  
}

// MARK: TKUIAttributionTableViewControllerDelegate

extension TKUITripOverviewCard: TKUIAttributionTableViewControllerDelegate {
  
  public func attributor(_ attributor: TKUIAttributionTableViewController, requestsWebsite url: URL) {
    TKUITripOverviewCard.config.presentAttributionHandler?(self, url)
  }
  
  public func requestsDismissal(attributor: TKUIAttributionTableViewController) {
    attributor.presentingViewController?.dismiss(animated: true, completion: nil)
  }
  
}
