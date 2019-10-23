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
    // required
    let searchText: Observable<String>
    let tappedDone: Signal<Void>
    
    // optional
    var selected: Signal<Item> = .empty()
    var selectedSearchMode: Signal<TKUIRoutingResultsViewModel.SearchMode> = .empty()
    var tappedSwap: Signal<Void> = .empty()
  }
  
  init(origin: MKAnnotation? = nil, destination: MKAnnotation? = nil, biasMapRect: MKMapRect = .null, inputs: UIInput, providers: [TKAutocompleting]? = nil) {

    let origin = origin ?? TKLocationManager.shared.currentLocation
    let providers = providers ?? TKUIRoutingResultsCard.config.autocompletionDataProviders
    
    enum Action {
      case initial
      case typeText(String)
      case selectMode(TKUIRoutingResultsViewModel.SearchMode)
      case selectItem(Item)
      case selectResult(MKAnnotation)
      case swap
    }
    
    // -- The input to the helper AutocompletionVM

    struct SearchState {
      var originText: String = ""
      var destinationText: String = ""
      var mode: TKUIRoutingResultsViewModel.SearchMode = .destination
    }
    
    let initialSearch = SearchState(
      originText: (origin.title ?? nil) ?? "",
      destinationText: (destination?.title ?? nil) ?? "",
      mode: .destination
    )

    let searchActions: Observable<Action> = Observable.merge([
        inputs.searchText.map { .typeText($0) },
        inputs.selectedSearchMode.asObservable()
          .distinctUntilChanged().map { .selectMode($0) },
        inputs.selected.asObservable().map { .selectItem($0) },
        inputs.tappedSwap.asObservable().map { .swap },
      ]).startWith(.initial)

    let searchInput = searchActions.scan(into: initialSearch) { state, action in
      switch (action, state.mode) {
      case (.typeText(let text), .origin):
        state.originText = text
      case (.typeText(let text), .destination):
        state.destinationText = text
      
      case (.selectItem(.autocompletion(let result)), .origin):
        state.originText = result.title
      case (.selectItem(.autocompletion(let result)), .destination):
        state.destinationText = result.title

      case (.selectMode(let mode), _):
        state.mode = mode

      case (.swap, _):
        (state.originText, state.destinationText) = (state.destinationText, state.originText)
        // Not swapping mode on purpose
        
      default: break
      }
    }

    // Just the text for the active mode
    let searchText = searchInput
      .map { state -> String in
        switch state.mode {
        case .origin: return state.originText
        case .destination: return state.destinationText
        }
      }
    
    let autocompletionModel = TKUIAutocompletionViewModel(
      providers: providers,
      searchText: searchText,
      selected: inputs.selected,
      biasMapRect: biasMapRect
    )
    
    // -- Handling selections
    
    struct SelectionState {
      var origin: MKAnnotation? = nil
      var destination: MKAnnotation? = nil
      var mode: TKUIRoutingResultsViewModel.SearchMode = .destination
    }
    
    let selectionActions: Observable<Action> = Observable.merge([
        autocompletionModel.selection.asObservable().map { .selectResult($0) },
        inputs.tappedSwap.asObservable().map { .swap },
        searchInput.map { $0.mode }.distinctUntilChanged().map { .selectMode($0) },
      ]).startWith(.initial)

    let selections = selectionActions
      .scan(into: SelectionState(origin: origin, destination: destination)) { state, action in
        switch (action, state.mode) {
        case (.selectResult(let selection), .origin):
          state.origin = selection
        case (.selectResult(let selection), .destination):
          state.destination = selection
        case (.selectMode(let mode), _):
          state.mode = mode
        case (.swap, _):
          (state.origin, state.destination) = (state.destination, state.origin)
        default: break
        }
      }
    
    self.activeMode = searchInput.map { $0.mode }
      .distinctUntilChanged()
      .asDriver(onErrorDriveWith: .empty())
    
    originDestination = searchInput.map { ($0.originText, $0.destinationText) }
      .distinctUntilChanged { $0.0 == $1.0 && $0.1 == $1.1 }
      .asDriver(onErrorDriveWith: .empty())

    sections = autocompletionModel.sections
    
    triggerAction = autocompletionModel.triggerAction
    
    self.selections = inputs.tappedDone.asObservable()
      .withLatestFrom(selections)
      .filter { $0.origin != nil && $0.destination != nil }
      .map { ($0.origin!, $0.destination!) }
      .asSignal(onErrorSignalWith: .empty())
  }
  
  let activeMode: Driver<TKUIRoutingResultsViewModel.SearchMode>
  
  let originDestination: Driver<(origin: String, destination: String)>
  
  let sections: Driver<[Section]>
  
  let selections: Signal<(MKAnnotation, MKAnnotation)>
  
  let triggerAction: Signal<TKAutocompleting>
}
