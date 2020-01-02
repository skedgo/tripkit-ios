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
  
  init(trip: Trip) {
    self.trip = trip
    
    titles = trip.rx.titles
    
    sections = Driver.just(TKUITripOverviewViewModel.buildSections(for: trip))
    
    dataSources = Driver.just(trip.tripGroup.sources)
    
    refreshMap = TKUITripOverviewViewModel.fetchContentOfServices(in: trip)
      .asSignal(onErrorSignalWith: .empty())
  }
  
  let trip: Trip

  let titles: Driver<(title: String, subtitle: String?)>
  
  let sections: Driver<[Section]>
  
  let dataSources: Driver<[TKAPI.DataAttribution]>
  
  let refreshMap: Signal<Void>
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

