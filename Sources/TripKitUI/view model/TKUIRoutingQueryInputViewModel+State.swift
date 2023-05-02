//
//  TKUIRoutingQueryInputViewModel+State.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

extension TKUIRoutingQueryInputViewModel {
  
  enum UserAction {
    case typeText(String)
    case selectMode(TKUIRoutingResultsViewModel.SearchMode)
    case selectResult(MKAnnotation)
    case select(MKAnnotation, TKUIRoutingResultsViewModel.SearchMode)
    case swap
  }
  
  struct State {
    var origin: MKAnnotation?
    var originText: String
    var destination: MKAnnotation?
    var destinationText: String
    
    /// The active search mode, determines what field gets populated when selecting a
    /// search result.
    fileprivate var searchMode: TKUIRoutingResultsViewModel.SearchMode
    
    /// Which mode to switch to. Typically is same as `searchMode` but can switch to `nil`
    /// when from and to are set and UI should select "Route"
    var mode: TKUIRoutingResultsViewModel.SearchMode?
  }

  static func buildState(origin: MKAnnotation, destination: MKAnnotation?, startMode: TKUIRoutingResultsViewModel.SearchMode?, inputs: UIInput, selection: Signal<MKAnnotation>) -> Observable<State> {
    
    let userActions: Observable<UserAction> = Observable.merge([
        selection.asObservable().map { .selectResult($0) },
        inputs.tappedSwap.asObservable().map { .swap },
        inputs.searchText.distinctUntilChanged { $0.0 == $1.0 }.map { .typeText($0.0) },
        inputs.selectedSearchMode.asObservable().distinctUntilChanged().map { .selectMode($0) },
        inputs.accessoryCallback.asObservable().map { .select($0, $1) }
      ])

    let initialState = State(
      origin: origin,
      originText: (origin.title ?? nil) ?? "",
      destination: destination,
      destinationText: (destination?.title ?? nil) ?? "",
      searchMode: startMode ?? .destination,
      mode: startMode ?? .destination
    )
    
    let state: Observable<State> = userActions
      .scan(into: initialState) { state, action in
        switch (action, state.searchMode) {
        case (.typeText(let text), .origin):
          // When we have a new search text, we also need to clear the
          // underlying annotation. Otherwise, the query will continue
          // with previous annotation regardless of what's being typed.
          //
          // Note that we also check if the text has changed. This is
          // because when we first load the query input view, we will
          // pre-populate the search field with the existing address,
          // which triggers this code path, and if we clear the
          // underlying annotation, it'd mean we cannot route despite
          // the user hasn't made any changes to the previous query
          // request.
          if text != state.originText {
            state.originText = text
            state.origin = nil
          }
          
        case (.typeText(let text), .destination):
          // See above explanation.
          if text != state.destinationText {
            state.destinationText = text
            state.destination = nil
          }

        case (.selectResult(let selection), .origin),
             (.select(let selection, .origin), _):
          state.origin = selection
          state.originText = (selection.title ?? nil) ?? ""
          
          // Switch to destination if it's not set yet, otherwise stay on
          // "origin" and indicate we're done.
          state.searchMode = state.destination == nil ? .destination : .origin
          state.mode = state.destination == nil ? .destination : nil
        
        case (.selectResult(let selection), .destination),
             (.select(let selection, .destination), _):
          state.destination = selection
          state.destinationText = (selection.title ?? nil) ?? ""

          // Switch to origin if it's not set yet, otherwise stay on
          // "destination" and indicate we're done.
          state.searchMode = state.origin == nil ? .origin : .destination
          state.mode = state.origin == nil ? .origin : nil

        case (.selectMode(let mode), _):
          state.searchMode = mode
          state.mode = mode
        
        case (.swap, _):
          state.mode = state.mode ?? .destination
          (state.origin, state.destination) = (state.destination, state.origin)
          (state.originText, state.destinationText) = (state.destinationText, state.originText)
        }
      }
      .startWith(initialState)
    
    return state
  }
  
}
