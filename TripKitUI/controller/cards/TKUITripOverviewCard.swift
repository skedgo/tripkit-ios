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
    let trips = trip.request.sortedVisibleTrips()
    guard let index = trips.index(of: trip) else { preconditionFailure() }
    
    let cards = trips.enumerated().map { TKUITripOverviewCard(trip: $1, index: $0) }
    
    // TODO: Give some meaningful title?
    self.init(title: trip.request.timeSorterTitle(), cards: cards, initialPage: index)
    
    // TODO: Localize
    headerRightAction = (title: "Start", onPress: { index in
      cards[index].enterModeByMode()
    })
  }
  
}


public class TKUITripOverviewCard: TGTableCard {
  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUITripOverviewCardModel.Section>(
    configureCell: { ds, tv, ip, item in
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      cell.textLabel?.text = item.title
      cell.detailTextLabel?.text = item.subtitle
      cell.imageView?.image = item.icon
      return cell
    }
  )
  
  private let cardModel: TKUITripOverviewCardModel
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
    guard let cardView = cardView as? TGTableCardView else {
      preconditionFailure()
    }
    
    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    cardView.tableView.dataSource = nil
    cardModel.sections
      .bind(to: cardView.tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // Handling selections
    cardView.tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] in
        self.enterModeByMode(for: self.dataSource[$0])
      })
      .disposed(by: disposeBag)
  }
  

  override public func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    // FIXME: Move to a delegate
    // SGScreenshotFeedback.sharedInstance.object = cardModel.trip
  }
  
  
  func enterModeByMode(for item: TKUITripOverviewCardModel.SegmentOverview) {
    guard let mapManager = self.mapManager as? TKUITripMapManager else { preconditionFailure() }
    
    let segment = cardModel.segment(for: item)
    controller?.push(TGPageCard(forModeByModeHighlighting: segment, mapManager: mapManager))
  }

  func enterModeByMode() {
    guard let mapManager = self.mapManager as? TKUITripMapManager else { preconditionFailure() }
    controller?.push(TGPageCard(forModeByModeWith: mapManager))
  }
  
}
