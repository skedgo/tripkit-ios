//
//  TKUIHomeViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

import RxSwift
import RxCocoa

public class TKUIHomeViewModel {
  
  struct SearchInput {
    var searchInProgress: Driver<Bool>
    var searchText: Observable<(String, forced: Bool)>
    var itemSelected: Signal<Item>
    var itemAccessoryTapped: Signal<Item>? = nil
    var refresh: Signal<Void> = .never()
    var biasMapRect: Driver<MKMapRect> = .just(.null)
  }
  
  private(set) var componentViewModels: [TKUIHomeComponentViewModel]!
  
  init(
    componentViewModels: [TKUIHomeComponentViewModel],
    actionInput: Signal<TKUIHomeCard.ComponentAction>,
    customizationInput: Signal<[TKUIHomeCard.CustomizedItem]>,
    searchInput: SearchInput
  ) {
    
    // When not searching
    
    self.componentViewModels = componentViewModels
    
    let fullContent = Self.fullContent(for: componentViewModels)
    
    let startCustomization: [TKUIHomeCard.CustomizedItem] =
      componentViewModels.compactMap { component in
        component.customizerItem.map { .init(fromUserDefaultsWithId: component.identity, item: $0) }
      }
    
    let customization = customizationInput
      .asObservable()
      .startWith(startCustomization)

    let baseContent = Self.customizedContent(full: fullContent, customization: customization)
    
    let componentNext = Self.buildNext(
      for: Signal.merge(componentViewModels.map(\.nextAction)),
      customization: customization
    )

    let actionNext = Self.buildNext(
      for: actionInput,
      customization: customization
    )
    
    // When searching

    let (searchContent, searchNext, searchError) = Self.searchContent(for: searchInput)
    
    
    // Combined
    
    let isSearching = searchInput.searchInProgress
      .startWith(false)
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: false)
    
    sections = Driver.combineLatest(baseContent, searchContent.startWith([]), isSearching) { $2 ? $1 : $0 }
    next = Signal.merge(componentNext, actionNext, searchNext)
    error = searchError
  }
  
  let sections: Driver<[Section]>
  
  let next: Signal<NextAction>
  
  let error: Signal<Error>
}



extension TKUIHomeViewModel.Section {
  init(_ content: TKUIHomeComponentContent, identity: String) {
    self.identity = identity
    self.headerConfiguration = content.header
    self.items = content.items.map { .component($0) }
  }
}
