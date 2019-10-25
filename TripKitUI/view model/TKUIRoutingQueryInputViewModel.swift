//
//  TKUIRoutingQueryInputViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

#if TK_NO_MODULE
#else
  import TripKit
#endif

class TKUIRoutingQueryInputViewModel {
  
  typealias Item = TKUIAutocompletionViewModel.Item
  typealias Section = TKUIAutocompletionViewModel.Section

  struct UIInput {
    let searchText: Observable<String>
    let tappedDone: Signal<Void>
    var selected: Signal<Item> = .empty()
    var selectedSearchMode: Signal<TKUIRoutingResultsViewModel.SearchMode> = .empty()
    var tappedSwap: Signal<Void> = .empty()
  }
  
  init(origin: MKAnnotation? = nil, destination: MKAnnotation? = nil, biasMapRect: MKMapRect = .null, inputs: UIInput, providers: [TKAutocompleting]? = nil) {

    let origin = origin ?? TKLocationManager.shared.currentLocation
    let providers = providers ?? TKUIRoutingResultsCard.config.autocompletionDataProviders
    
    let autocompletionModel = TKUIAutocompletionViewModel(
      providers: providers,
      searchText: inputs.searchText.startWith(""),
      selected: inputs.selected,
      biasMapRect: biasMapRect
    )
    
    let state = Self.buildState(
        origin: origin, destination: destination,
        inputs: inputs, selection: autocompletionModel.selection
      )
      .share(replay: 1, scope: .whileConnected)
    
    activeMode = state.map { $0.mode }
      .distinctUntilChanged()
      .asDriver(onErrorDriveWith: .empty())
    
    originDestination = state.map { ($0.originText, $0.destinationText) }
      .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
      .asDriver(onErrorDriveWith: .empty())

    sections = autocompletionModel.sections

    triggerAction = autocompletionModel.triggerAction
    
    enableRouteButton = state
      .map { $0.origin != nil && $0.destination != nil }
      .asDriver(onErrorJustReturn: false)

    selections = inputs.tappedDone.asObservable()
      .withLatestFrom(state)
      .filter { $0.origin != nil && $0.destination != nil }
      .map { ($0.origin!, $0.destination!) }
      .asSignal(onErrorSignalWith: .empty())
}
  
  let activeMode: Driver<TKUIRoutingResultsViewModel.SearchMode>
  
  let originDestination: Driver<(origin: String, destination: String)>
  
  let sections: Driver<[Section]>
  
  let enableRouteButton: Driver<Bool>
  
  let selections: Signal<(MKAnnotation, MKAnnotation)>
  
  let triggerAction: Signal<TKAutocompleting>
}
