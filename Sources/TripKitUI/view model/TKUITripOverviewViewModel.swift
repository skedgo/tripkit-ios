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
        return TKRealTimeFetcher.rx.streamUpdates($0, active: inputs.isVisible.asObservable())
          .startWith($0)
          .catchAndReturn($0)
      }
      .share(replay: 1, scope: .forever)
        
    sections = tripUpdated
      .map(Self.buildSections)
      .asDriver { assertionFailure("Unexpected error: \($0)"); return .never() }
    
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

// MARK: - Navigation

extension TKUITripOverviewViewModel {
  enum Next {
    case handleSelection(TKSegment)
    case showAlerts([TKAlert])
    case showAlternativeRoutes(TripRequest)
  }
}
