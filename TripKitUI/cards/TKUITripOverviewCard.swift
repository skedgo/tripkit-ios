//
//  TKUITripOverviewCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
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
        let trip = card.cardModel.trip
        tripHandler(card, trip)
      })
    }
  }
  
}


public class TKUITripOverviewCard: TGTableCard {
  
  public static var presentSegmentHandler: ((TKUITripOverviewCard, TKSegment) -> Void)?

  public static var startTripHandler: ((TKUITripOverviewCard, Trip) -> Void)?

  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUITripOverviewCardModel.Section>(
    configureCell: { ds, tv, ip, item in
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel?.text = item.title
      cell.detailTextLabel?.text = item.subtitle
      cell.imageView?.image = item.icon
      return cell
    }
  )
  
  fileprivate let cardModel: TKUITripOverviewCardModel
  private let disposeBag = DisposeBag()
  
  public init(trip: Trip, index: Int? = nil) {
    cardModel = TKUITripOverviewCardModel(trip: trip)
    
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
    cardModel.sections
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // Handling segment selections
    if let segmentHandler = TKUITripOverviewCard.presentSegmentHandler {
      tableView.rx.itemSelected
        .map { (self, self.cardModel.segment(for: self.dataSource[$0])) }
        .subscribe(onNext: segmentHandler)
        .disposed(by: disposeBag)
    }
  }
  
  
  override public func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
   
    TKUICustomization.shared.feedbackActiveItemHandler?(cardModel.trip)
  }
  
}
