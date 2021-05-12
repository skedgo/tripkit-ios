//
//  TKUITripOverviewViewModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import TripKit

class TKUITripOverviewViewModel {
  
  struct UIInput {
    var selected: Signal<Item> = .empty()
    var isVisible: Driver<Bool> = .just(true)
  }
  
  init(presentedTrip: Infallible<Trip>, inputs: UIInput = UIInput()) {
    
    titles = presentedTrip
      .asDriver(onErrorDriveWith: .empty())
      .flatMapLatest { $0.rx.titles }
    
    dataSources = presentedTrip
      .asDriver(onErrorDriveWith: .empty())
      .map { $0.tripGroup.sources }
    
    let tripChanged: Observable<Trip> = presentedTrip
      .asObservable()
      .distinctUntilChanged { $0.persistentId() == $1.persistentId() }
    
    let servicesFetched = presentedTrip
      .asObservable()
      .flatMapLatest { trip in
        Self.fetchContentOfServices(in: trip).map { trip }
      }

    refreshMap = Observable.merge(tripChanged, servicesFetched)
      .asSignal(onErrorSignalWith: .empty())
    
    let tripUpdated: Observable<Trip> = presentedTrip
      .asObservable()
      .flatMapLatest {
        return TKBuzzRealTime.rx.streamUpdates($0, active: inputs.isVisible.asObservable())
          .startWith($0)
      }
      .share(replay: 1, scope: .forever)
        
    sections = tripUpdated
      .map(Self.buildSections)
      .asDriver(onErrorJustReturn: [])
    
    actions = tripUpdated
      .map { updated -> ([TKUITripOverviewCard.TripAction], Trip) in
        (TKUITripOverviewCard.config.tripActionsFactory?(updated) ?? [], updated)
      }
      .asDriver(onErrorDriveWith: .never())
    
    next = inputs.selected.compactMap { item -> Next? in
        switch item {
        case .impossible(let segment, _):
          let request = segment.insertRequestStartingHere()
          return .showAlternativeRoutes(request)
        
        case .alert(let item):
          return .showAlerts(item.alerts)
          
        case .moving, .stationary, .terminal:
          guard let segment = item.segment else { return nil }
          return .handleSelection(segment)
        }
      }
    
  }
  
  let titles: Driver<(title: String, subtitle: String?)>
  
  let sections: Driver<[Section]>
  
  let actions: Driver<([TKUITripOverviewCard.TripAction], Trip)>
  
  let dataSources: Driver<[TKAPI.DataAttribution]>
  
  let refreshMap: Signal<Trip>
  
  let next: Signal<Next>
  
}

extension TKUITripOverviewViewModel {
  
  convenience init(initialTrip: Trip) {
    self.init(presentedTrip: .just(initialTrip))
  }
  
}

fileprivate extension Reactive where Base == Trip {
  
  static func titles(for trip: Trip) -> (title: String, subtitle: String?) {
    let timeTitles = trip.timeTitles(capitalize: true)
    return (
      timeTitles.title,
      timeTitles.subtitle
    )
  }
  
  var titles: Driver<(title: String, subtitle: String?)> {
    return Observable.merge(observe(Date.self, "arrivalTime"), observe(Date.self, "departureTime"))
      .map { [unowned base] _ in Self.titles(for: base) }
      .asDriver(onErrorDriveWith: .empty())
  }
  
}

// MARK: - Navigation

extension TKUITripOverviewViewModel {
  
  enum Next {
    case handleSelection(TKSegment)
    case showAlerts([TKAlert])
    case showAlternativeRoutes(TripRequest)
  }
  
}
