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
  
  init(componentViewModels: [TKUIHomeComponentViewModel], searchInput: SearchInput) {
    
    // When not searching
    
    self.componentViewModels = componentViewModels
    
    let componentSections = componentViewModels
      .enumerated()
      .map { index, component in
        component.homeCardSection.map { (index: index, TKUIHomeViewModel.Section($0)) }
      }
    let componentUpdates = Driver.merge(componentSections).asObservable()
    
    let baseContent = componentUpdates.scan(into: SectionContent(capacity: componentViewModels.count)) { content, update in
        content.sections[update.index] = update.1
      }.map { content in
        // Only include existing sections that either have items or a header action
        return content.sections
          .compactMap { $0 }
          .filter { !$0.items.isEmpty || $0.headerConfiguration?.action != nil }
      }
      .throttle(.milliseconds(500), latest: true, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: [])
      .startWith([])
    
    // When searching

    let (searchContent, searchNext, searchError) = Self.searchContent(for: searchInput)
    
    
    // Combined
    
    let isSearching = searchInput.searchInProgress
      .startWith(false)
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: false)
    
    sections = Driver.combineLatest(baseContent, searchContent.startWith([]), isSearching) { $2 ? $1 : $0 }
    next = Signal.merge(componentViewModels.map(\.nextAction) + [searchNext])
    error = searchError
  }
  
  let sections: Driver<[Section]>
  
  let next: Signal<TKUIHomeCardNextAction>
  
  let error: Signal<Error>
}

fileprivate extension TKUIHomeViewModel {
  struct SectionContent {
    var sections: [Section?]
    
    init(capacity: Int) {
      sections = (0..<capacity).map { _ in Optional<TKUIHomeViewModel.Section>.none }
    }
  }
}

extension TKUIHomeViewModel.Section {
  init(_ content: TKUIHomeComponentContent) {
    self.identity = content.identity
    self.headerConfiguration = content.header
    self.items = content.items.map { .component($0) }
  }
}
