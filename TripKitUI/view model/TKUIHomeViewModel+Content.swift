//
//  TKUIHomeViewModel+Content.swift
//  TripKit-iOS
//
//  Created by Brian Huang on 28/7/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension TKUIHomeViewModel {
  
  enum Item {
    case component(TKUIHomeComponentItem)
    case search(TKUIAutocompletionViewModel.Item)
  }

  public struct HeaderConfiguration {
    public let title: String
    public var action: (title: String, handler: () -> TKUIHomeCard.ComponentAction)?
    
    public init(title: String, action: (String, () -> TKUIHomeCard.ComponentAction)? = nil) {
      self.title = title
      self.action = action
    }
  }
  
  struct Section {
    let identity: String
    var items: [Item]
    var headerConfiguration: HeaderConfiguration?
    
    init(identity: String, items: [Item], headerConfiguration: HeaderConfiguration? = nil) {
      self.identity = identity
      self.items = items
      self.headerConfiguration = headerConfiguration
    }
  }
}

// MARK: - Build

extension TKUIHomeViewModel {
  
  /// Builds the full and non-customized content
  static func fullContent(for components: [TKUIHomeComponentViewModel]) -> Driver<[TKUIHomeViewModel.Section]> {
    
    let componentSections = components
      .map { component in
        component.homeCardSection.map { Section($0, identity: component.identity) }
      }
      .enumerated()
      .map { index, driver in
        return driver.map { (index: index, $0) }
      }
    
    let componentUpdates = Driver.merge(componentSections).asObservable()
    
    return componentUpdates.scan(into: SectionContent(capacity: componentSections.count)) { content, update in
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

  }
  
  private struct SectionContent {
    var sections: [Section?]
    
    init(capacity: Int) {
      sections = (0..<capacity).map { _ in Optional<TKUIHomeViewModel.Section>.none }
    }
  }
  
  /// Takes the full content, applies the user's customization and provides back the filtered sections
  static func customizedContent(full: Driver<[TKUIHomeViewModel.Section]>, customization: Observable<[TKUIHomeCard.CustomizedItem]>) -> Driver<[TKUIHomeViewModel.Section]> {
    
    guard !TKUIHomeCard.config.ignoreComponentCustomization else { return full }
    
    return Driver.combineLatest(full, customization.asDriver(onErrorJustReturn: [])) { full, customization -> [TKUIHomeViewModel.Section] in
      
      return full
        .filter { candidate in
          customization.first { $0.id == candidate.identity }?.isEnabled ?? true
        }
        .sorted { first, second in
          let firstIndex = customization.firstIndex { $0.id == first.identity }
          let secondIndex = customization.firstIndex { $0.id == second.identity }
          if let first = firstIndex, let second = secondIndex {
            return first < second
          } else if firstIndex == nil {
            return false
          } else {
            return true
          }
        }
    }
  }
}

// MARK: - RxDataSources

extension TKUIHomeViewModel.Item: Equatable {
}

func == (lhs: TKUIHomeViewModel.Item, rhs: TKUIHomeViewModel.Item) -> Bool {
  switch (lhs, rhs) {
  case let (.component(left), .component(right)): return left.identity == right.identity
  case let (.search(left), .search(right)): return left == right
  default: return false
  }
}

extension TKUIHomeViewModel.Item: IdentifiableType {
  
  typealias Identity = String
  
  var identity: Identity {
    switch self {
    case .component(let item): return item.identity
    case .search(let item): return item.identity
    }
  }
}

extension TKUIHomeViewModel.Section: AnimatableSectionModelType {
  
  typealias Identity = String
  
  init(original: TKUIHomeViewModel.Section, items: [TKUIHomeViewModel.Item]) {
    self = original
    self.items = items
  }
  
}
