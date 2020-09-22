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
import RxDataSources

public class TKUIHomeViewModel {
  
  struct CardInputEvent {
    var searchInProgress: Signal<Bool>
  }
  
  private(set) var componentViewModels: [TKUIHomeComponentViewModel]!
  
  init(componentViewModels: [TKUIHomeComponentViewModel], event: CardInputEvent) {
    self.componentViewModels = componentViewModels
    
    let isSearching = event.searchInProgress
      .startWith(false)
      .distinctUntilChanged()
      .asObservable()
      .share(replay: 1, scope: .forever)
    
    let componentSections = componentViewModels
      .enumerated()
      .map { index, component in
        component.homeCardSections(isSearching).map { (index: index, $0) }
      }
    let componentUpdates = Observable.merge(componentSections)
    
    sections = componentUpdates.scan(into: SectionContent(capacity: componentViewModels.count)) { content, update in
        content.sections[update.index] = update.1
      }.map { content in
        // Only include existing sections that either have items or a header action
        return content.sections
          .compactMap { $0 }
          .filter { !$0.items.isEmpty || $0.headerConfiguration?.action != nil }
      }
      .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: [])
      .startWith([])
    
    next = Signal.merge(componentViewModels.map(\.nextAction))
  }
  
  let sections: Driver<[Section]>
  
  let next: Signal<TKUIHomeCardNextAction>

}

fileprivate extension TKUIHomeViewModel {
  struct SectionContent {
    var sections: [Section?]
    
    init(capacity: Int) {
      sections = (0..<capacity).map { _ in Optional<TKUIHomeViewModel.Section>.none }
    }
  }
}
