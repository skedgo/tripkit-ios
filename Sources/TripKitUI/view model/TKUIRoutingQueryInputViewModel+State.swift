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
    case swap
  }
  
  struct State {
    var origin: MKAnnotation?
    var originText: String
    var destination: MKAnnotation?
    var destinationText: String
    var mode: TKUIRoutingResultsViewModel.SearchMode
  }

  static func buildState(origin: MKAnnotation, destination: MKAnnotation?, startMode: TKUIRoutingResultsViewModel.SearchMode?, inputs: UIInput, selection: Signal<MKAnnotation>) -> Observable<State> {
    
    let userActions: Observable<UserAction> = Observable.merge([
        selection.asObservable().map { .selectResult($0) },
        inputs.tappedSwap.asObservable().map { .swap },
        inputs.searchText.distinctUntilChanged { $0.0 == $1.0 }.map { .typeText($0.0) },
        inputs.selectedSearchMode.asObservable().distinctUntilChanged().map { .selectMode($0) },
      ])

    let initialState = State(
      origin: origin,
      originText: (origin.title ?? nil) ?? "",
      destination: destination,
      destinationText: (destination?.title ?? nil) ?? "",
      mode: startMode ?? .destination
    )
    
    return userActions
      .scan(into: initialState) { state, action in
        switch (action, state.mode) {
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

        case (.selectResult(let selection), .origin):
          state.origin = selection
          state.originText = (selection.title ?? nil) ?? ""
          state.mode = .destination
        
        case (.selectResult(let selection), .destination):
          state.destination = selection
          state.destinationText = (selection.title ?? nil) ?? ""
          state.mode = .origin

        case (.selectMode(let mode), _):
          state.mode = mode
        
        case (.swap, _):
          (state.origin, state.destination) = (state.destination, state.origin)
          (state.originText, state.destinationText) = (state.destinationText, state.originText)
        }
      }
      .startWith(initialState)
  }
  
}
