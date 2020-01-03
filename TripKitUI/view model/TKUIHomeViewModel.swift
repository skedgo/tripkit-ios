//
//  TKUIHomeViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

public class TKUIHomeViewModel {
  
  typealias Section = TKUIAutocompletionViewModel.Section
  typealias Item = TKUIAutocompletionViewModel.Item
  
  let searchViewModel: TKUIAutocompletionViewModel
  let nearbyViewModel: TKUINearbyViewModel
  
  struct ListInput {
    var searchText: Observable<(String, forced: Bool)> = .empty()
    var selected: Signal<Item> = .empty()
    var accessorySelected: Signal<Item>? = nil
  }
  
  struct MapInput {
    var mapRect: Driver<MKMapRect> = .just(.null)
    var selected: Signal<TKUIIdentifiableAnnotation?> = .empty()
  }
  
  init(listInput: ListInput, mapInput: MapInput = MapInput()) {
    
    // We use Apple & SkedGo if none is provided for autocompletion
    let autocompleteDataProviders = TKUIHomeCard.config.autocompletionDataProviders ?? [TKAppleGeocoder(), TKSkedGoGeocoder()]
    
    // TODO: Have a "Search here" button, too? So if the map
    //       rect changes, we inject that, and pressing that
    //       redoes the search?

    searchViewModel = TKUIAutocompletionViewModel(
      providers: autocompleteDataProviders,
      searchText: listInput.searchText,
      selected: listInput.selected,
      accessorySelected: listInput.accessorySelected,
      biasMapRect: mapInput.mapRect
    )
    
    nearbyViewModel = TKUINearbyViewModel(
      mapInput: TKUINearbyViewModel.MapInput(
        mapRect: mapInput.mapRect,
        selection: mapInput.selected
      )
    )

    sections = searchViewModel.sections
    selection = searchViewModel.selection
    accessorySelection = searchViewModel.accessorySelection
    triggerAction = searchViewModel.triggerAction
    
    // TODO: Either do something with nearbyViewModel.next,
    //       or don't pass mapInput.selected to NearbyViewModel
    //       and handle it directly instead.
    
    mapAnnotations = nearbyViewModel.mapAnnotations
    mapOverlays = nearbyViewModel.mapOverlays
    mapAnnotationSelected = nearbyViewModel.next
  }

  // List content

  let sections: Driver<[Section]>
  
  let selection: Signal<MKAnnotation>
  
  let accessorySelection: Signal<MKAnnotation>
  
  let triggerAction: Signal<TKAutocompleting>

  // Map content

  let mapAnnotations: Driver<[TKUIIdentifiableAnnotation]>
  
  let mapOverlays: Driver<[MKOverlay]>
  
  let mapAnnotationSelected: Signal<TKUINearbyViewModel.Next>

}
