//
//  TKUIHomeViewModel+Search.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 13.10.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import TripKit

extension TKUIHomeViewModel {
  
  static func searchContent(for searchInput: SearchInput) -> (Driver<[Section]>, Signal<NextAction>, Signal<Error>) {
    
    // We use Apple & SkedGo if none is provided for autocompletion
    let autocompleteDataProviders = TKUIHomeCard.config.autocompletionDataProviders ?? [TKAppleGeocoder(), TKTripGoGeocoder()]
    
    let searchViewModel = TKUIAutocompletionViewModel(
      providers: autocompleteDataProviders,
      searchText: searchInput.searchText,
      selected: searchInput.itemSelected.compactMap(\.autocompletionItem),
      accessorySelected: searchInput.itemAccessoryTapped?.compactMap(\.autocompletionItem),
      refresh: searchInput.refresh,
      biasMapRect: searchInput.biasMapRect
    )
    
    let content: Driver<[Section]> = searchViewModel.sections.map { sections in
      let items = sections.flatMap { $0.items.map { TKUIHomeViewModel.Item.search($0) } }
      return [TKUIHomeViewModel.Section(identity: "home-card-search", items: items, headerConfiguration: nil)]
    }
    
    let nextFromSelection = searchViewModel.selection
      .map { selection -> NextAction in
        switch selection {
        case .annotation(let city) where city is TKRegion.City:
          return .handleSelection(selection, component: nil)
        case .annotation(let annotation):
          return .push(TKUIRoutingResultsCard(destination: annotation), selection: annotation)
        case .result:
          return .handleSelection(selection, component: nil)
        }
      }
    
    let nextFromAccessory = searchViewModel.accessorySelection
      .compactMap { selection -> NextAction? in
        switch (selection, TKUICustomization.shared.locationInfoTapHandler) {
        case (.annotation(let stop as TKUIStopAnnotation), _):
          return .push(TKUITimetableCard(stops: [stop]), selection: stop)
        case (.annotation(let annotation), .some(let tapHandler)):
          switch tapHandler(.init(annotation: annotation, routeButton: .allowed)) {
          case .push(let card):
            return .push(card, selection: annotation)
          }
          
        case (.annotation, _), (.result, _):
          assertionFailure("Unexpected annotation: \(selection)")
          return nil
        }
      }
    
    let nextFromAction = searchViewModel.triggerAction
      .map { provider in
        NextAction.handleAction(handler: { controller in
          provider.triggerAdditional(presenter: controller)
        })
      }
    
    let next = Signal.merge(nextFromSelection, nextFromAccessory, nextFromAction)
    
    return (content, next, searchViewModel.error)
  }
  
}

extension TKUIHomeViewModel.Item {
  fileprivate var autocompletionItem: TKUIAutocompletionViewModel.Item? {
    switch self {
    case .component: return nil
    case .search(let item): return item
    }
  }
}
