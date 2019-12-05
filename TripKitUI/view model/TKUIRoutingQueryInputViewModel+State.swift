//
//  TKUIRoutingQueryInputViewModel+State.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

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

  static func buildState(origin: MKAnnotation, destination: MKAnnotation?, inputs: UIInput, selection: Signal<MKAnnotation>) -> Observable<State> {
    
    let userActions: Observable<UserAction> = Observable.merge([
        selection.asObservable().map { .selectResult($0) },
        inputs.tappedSwap.asObservable().map { .swap },
        inputs.searchText.map { .typeText($0.0) },
        inputs.selectedSearchMode.asObservable().map { .selectMode($0) },
      ])

    let initialState = State(
      origin: origin,
      originText: (origin.title ?? nil) ?? "",
      destination: destination,
      destinationText: (destination?.title ?? nil) ?? "",
      mode: .destination
    )
    
    return userActions
      .scan(into: initialState) { state, action in
        switch (action, state.mode) {
        case (.typeText(let text), .origin):
          state.originText = text
        case (.typeText(let text), .destination):
          state.destinationText = text

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
