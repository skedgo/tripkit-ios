//
//  TKUIRoutingQueryInputViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TGCardViewController

import TripKit

@MainActor
class TKUIRoutingQueryInputViewModel {
  
  typealias Item = TKUIAutocompletionViewModel.Item
  typealias Section = TKUIAutocompletionViewModel.Section

  struct UIInput {
    let searchText: Observable<(String, forced: Bool)>
    let tappedRoute: Signal<Void>
    var tappedKeyboardDone: Signal<TKUIRoutingResultsViewModel.SearchMode> = .empty()
    var selected: Signal<Item> = .empty()
    var selectedSearchMode: Signal<TKUIRoutingResultsViewModel.SearchMode> = .empty()
    var tappedSwap: Signal<Void> = .empty()
    var accessoryTapped: Signal<Item>? = nil
    var accessoryCallback: Signal<(MKAnnotation, TKUIRoutingResultsViewModel.SearchMode)> = .empty()
  }
  
  enum Next {
    case route(origin: MKAnnotation, destination: MKAnnotation)
    case push(TGCard)
    case popBack(select: MKAnnotation, mode: TKUIRoutingResultsViewModel.SearchMode, route: Bool)
  }
  
  init(origin: MKAnnotation? = nil, destination: MKAnnotation? = nil, biasMapRect: MKMapRect = .null, startMode: TKUIRoutingResultsViewModel.SearchMode? = nil, inputs: UIInput, providers: [TKAutocompleting]? = nil) {

    let includeCurrentLocation = TKLocationManager.shared.featureIsAvailable
    let start: MKAnnotation?
    if let provided = origin {
      start = provided
    } else if includeCurrentLocation {
      start = TKLocationManager.shared.currentLocation
    } else {
      start = nil
    }
    
    let providers = providers ?? TKUIRoutingResultsCard.config.autocompletionDataProviders
    
    let autocompletionModel = TKUIAutocompletionViewModel(
      providers: providers,
      includeCurrentLocation: includeCurrentLocation,
      searchText: inputs.searchText.startWith(("", forced: false)),
      selected: inputs.selected,
      accessorySelected: inputs.accessoryTapped,
      biasMapRect: .just(biasMapRect)
    )
    
    let state = Self.buildState(
        origin: start, destination: destination,
        startMode: startMode,
        inputs: inputs, selection: autocompletionModel.selection
      )
      .share(replay: 1, scope: .whileConnected)
    
    activeMode = state.map(\.mode)
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

    let selections = inputs.tappedRoute.asObservable()
      .withLatestFrom(state)
      .filter { $0.origin != nil && $0.destination != nil }
      .map { Next.route(origin: $0.origin!, destination: $0.destination!) }
      .asAssertingSignal()
    
    let routeASAP = state
      .filter { $0.mode == nil && $0.origin != nil && $0.destination != nil }
      .map { Next.route(origin: $0.origin!, destination: $0.destination!) }
      .asAssertingSignal()

    // If we have a `TKUICustomization.shared.locationInfoTapHandler` set, we:
    // - Add an (i) in the TKUIAutocompletionViewModel, which then triggers
    //   `accessorySelection` on its tap.
    // - When that is tapped, we grab the current state, and ask the handler
    //   to present the location *along with a context sensitive route* button
    // - The handler should then push an appropriate card that includes that
    //   button.
    // - If the user then taps that button, we trigger the 'tap info route'
    //   publisher, which in turn asks the routing query input card to pop back
    //   to itself, and trigger the `accessoryCallback` publisher...
    // - Yikes. If that is triggered, we update the state accordingly, and
    //   optionally, dismiss the routing query input card.
    let tapInfoRoutePublisher = PublishSubject<Next>()
    let accessoryTaps: Signal<Next>
    if let handler = TKUICustomization.shared.locationInfoTapHandler {
      accessoryTaps = autocompletionModel.accessorySelection
        .asObservable()
        .withLatestFrom(state) { selection, state -> Next? in
          guard case .annotation(let annotation) = selection else {
            assertionFailure()
            return nil
          }

          let routeButton: TKUILocationInfo.RouteButton
          switch state.mode {
          case .origin:
            routeButton = .replace(title: Loc.StartHere, onTap: {
              tapInfoRoutePublisher.onNext(.popBack(select: annotation, mode: .origin, route: destination != nil))
            })
          case .destination, .none:
            routeButton = .replace(title: Loc.EndHere, onTap: {
              tapInfoRoutePublisher.onNext(.popBack(select: annotation, mode: .destination, route: true))
            })
          }
          
          switch handler(.init(annotation: annotation, routeButton: routeButton)) {
          case .push(let card):
            return .push(card)
          }
        }
        .compactMap { $0 }
        .asAssertingSignal()
    } else {
      accessoryTaps = .empty()
    }
    
    next = Signal.merge([
      routeASAP,
      selections,
      accessoryTaps,
      tapInfoRoutePublisher.asAssertingSignal()
    ])
}
  
  let activeMode: Driver<TKUIRoutingResultsViewModel.SearchMode?>
  
  let originDestination: Driver<(origin: String, destination: String)>
  
  let sections: Driver<[Section]>
  
  let enableRouteButton: Driver<Bool>
  
  let triggerAction: Signal<TKAutocompleting>
  
  let next: Signal<Next>
}
