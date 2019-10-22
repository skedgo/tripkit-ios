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
    let selectedSearchMode: Signal<TKUIRoutingResultsViewModel.SearchMode> = .empty()
    var tappedSwap: Signal<Void> = .empty()
  }
  
  init(origin: MKAnnotation? = nil, destination: MKAnnotation?, biasMapRect: MKMapRect = .null, inputs: UIInput) {

    let activeMode = inputs.selectedSearchMode
      .startWith(.destination)
      .asDriver(onErrorJustReturn: .destination)
    
    typealias SearchInput = (String, String, TKUIRoutingResultsViewModel.SearchMode)
    let initial: SearchInput = (
      (origin?.title ?? nil) ?? "",
      (destination?.title ?? nil) ?? "",
      .destination
    )
    
    #warning("FIXME: Handle swap")
    
    // Tracks text for each and active mode
    let searchInput =
      Observable.combineLatest(
        inputs.searchText,
        activeMode.asObservable()
      )
      .scan(initial) { acc, next -> SearchInput in
        switch next.1 {
        case .origin: return (next.0, acc.1, next.1)
        case .destination: return (acc.0, next.0, next.1)
        }
      }
      
    // Just the text for the active mode
    let searchText = searchInput
      .map { input -> String in
        switch input.2 {
        case .origin: return input.0
        case .destination: return input.1
        }
      }
    
    let autocompletionModel = TKUIAutocompletionViewModel(
      providers: TKUIRoutingResultsCard.config.autocompletionDataProviders,
      searchText: searchText,
      selected: inputs.selected,
      biasMapRect: biasMapRect
    )
    
    self.activeMode = activeMode
    
    #warning("Also handle tapping a result (which should then update the text")
    
    originText = searchInput.map { $0.0 }.asDriver(onErrorJustReturn: "")
    destinationText = searchInput.map { $0.1 }.asDriver(onErrorJustReturn: "")
    
    sections = autocompletionModel.sections
    
    triggerAction = autocompletionModel.triggerAction

    #warning("FIXME: Fix this up, doing a similar thing as above")
    
    selections = autocompletionModel.selection
  }
  
  let activeMode: Driver<TKUIRoutingResultsViewModel.SearchMode>
  
  let originText: Driver<String>
  
  let destinationText: Driver<String>
  
  let sections: Driver<[Section]>
  
  let selections: Signal<(MKAnnotation, MKAnnotation)>
  
  let triggerAction: Signal<TKAutocompleting>
}
