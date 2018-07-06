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
    
    if let tripHandler = TKUITripOverviewCard.startTripHandler {
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
  
  public static var presentSegmentHandler: ((TKUITripOverviewCard, TKSegment) -> Void)?

  public static var startTripHandler: ((TKUITripOverviewCard, Trip) -> Void)?

  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUITripOverviewViewModel.Section>(
    configureCell: { ds, tv, ip, item in
      switch item {
      case .start(let item):
        return TKUITripOverviewCard.terminalCell(for: item, isStart: true, tableView: tv, indexPath: ip)
      case .end(let item):
        return TKUITripOverviewCard.terminalCell(for: item, isStart: false, tableView: tv, indexPath: ip)
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
    
    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    tableView.dataSource = nil
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // Handling segment selections
    if let segmentHandler = TKUITripOverviewCard.presentSegmentHandler {
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
  
  private static func terminalCell(for terminal: TKUITripOverviewViewModel.TerminalItem, isStart: Bool, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.textLabel?.text = terminal.title
    cell.detailTextLabel?.text = terminal.subtitle
    return cell
  }

  private static func stationaryCell(for stationary: TKUITripOverviewViewModel.StationaryItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.textLabel?.text = stationary.title
    cell.detailTextLabel?.text = stationary.subtitle
    return cell
  }

  private static func movingCell(for moving: TKUITripOverviewViewModel.MovingItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    cell.textLabel?.text = moving.title
    cell.detailTextLabel?.text = moving.notes
    cell.imageView?.image = moving.icon
    return cell
  }

}
