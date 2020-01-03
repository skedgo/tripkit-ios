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

#if TK_NO_MODULE
#else
  import TripKit
#endif

class TKUITripOverviewViewModel {
  
  struct UIInput {
    var selected: Signal<Item> = .empty()
  }
  
  init(trip: Trip, inputs: UIInput = UIInput()) {
    self.trip = trip
    
    titles = trip.rx.titles
    
    sections = Driver.just(TKUITripOverviewViewModel.buildSections(for: trip))
    
    dataSources = Driver.just(trip.tripGroup.sources)
    
    refreshMap = TKUITripOverviewViewModel.fetchContentOfServices(in: trip)
      .asSignal(onErrorSignalWith: .empty())
    
    // LATER: This can be changed to a `compactMap` in RxSwift 6
    next = inputs.selected.map { item -> Next? in
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
    .filter { $0 != nil }.map { $0!}
  }
  
  let trip: Trip

  let titles: Driver<(title: String, subtitle: String?)>
  
  let sections: Driver<[Section]>
  
  let dataSources: Driver<[TKAPI.DataAttribution]>
  
  let refreshMap: Signal<Void>
  
  let next: Signal<Next>
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
