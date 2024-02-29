//
//  TKUIHomeViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 19.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

@MainActor
class TKUIHomeViewModel {
  
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
    searchInput: SearchInput
  ) {
    
    // When not searching
    
    self.componentViewModels = componentViewModels
    
    let fullContent = Self.fullContent(for: componentViewModels)
    
    let customizationFromDefaults = NotificationCenter.default.rx
      .notification(.TKUIHomeComponentsCustomized)
      .map { _ in }
      .startWith(())
      .observe(on: MainScheduler.asyncInstance)
      .map { () -> [TKUIHomeCard.CustomizedItem] in
        let unsorted = componentViewModels.compactMap { component in
          component.customizerItem.map { TKUIHomeCard.CustomizedItem(fromUserDefaultsWithId: component.identity, item: $0) }
        }
        return TKUIHomeCard.sortedAsInDefaults(unsorted)
      }
      .share(replay: 1, scope: .whileConnected)

    let baseContent = Self.customizedContent(full: fullContent, customization: customizationFromDefaults)
    
    let componentNext = Self.buildNext(
      for: Signal.merge(componentViewModels.map(\.nextAction)),
      customization: customizationFromDefaults
    )

    let actionNext = Self.buildNext(
      for: actionInput,
      customization: customizationFromDefaults
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
  init?(_ content: TKUIHomeComponentContent, identity: String) {
    guard let items = content.items else { return nil }
    self.identity = identity
    self.headerConfiguration = content.header
    self.items = items.map { .component($0) }
  }
}
