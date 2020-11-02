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
    public var action: (title: String, handler: () -> TKUIHomeCardNextAction)?
    
    public init(title: String, action: (String, () -> TKUIHomeCardNextAction)? = nil) {
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
