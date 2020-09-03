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
import RxDataSources

/// This is the `item` that will be used in the context of
/// `RxTableViewSectionedAnimatedDataSource`
public protocol TKUIHomeComponentViewModelItem {
  
  /// This is a string that will be used by `RxTableViewSectionedAnimatedDataSource`
  /// to determine if two items are identical when animating cells in and out of a table view.
  var identity: String { get }
  
}

extension TKUIHomeViewModel {
  
  public struct Item {
    public let componentViewModelItem: TKUIHomeComponentViewModelItem
    
    public init(item: TKUIHomeComponentViewModelItem) {
      self.componentViewModelItem = item
    }
  }
  
  public struct Section {
    
    public struct HeaderConfiguration {
      public let title: String
      public var action: (title: String, handler: () -> TKUIHomeCardNextAction)?
      
      public init(title: String, action: (String, () -> TKUIHomeCardNextAction)? = nil) {
        self.title = title
        self.action = action
      }
    }
    
    public let identity: String
    public var items: [Item]
    public var headerConfiguration: HeaderConfiguration?
    
    public init(identity: String, items: [Item], headerConfiguration: HeaderConfiguration? = nil) {
      self.identity = identity
      self.items = items
      self.headerConfiguration = headerConfiguration
    }
    
  }

}

// MARK: - RxDataSources

extension TKUIHomeViewModel.Item: Equatable {
}

public func == (lhs: TKUIHomeViewModel.Item, rhs: TKUIHomeViewModel.Item) -> Bool {
  return lhs.componentViewModelItem.identity == rhs.componentViewModelItem.identity
}

extension TKUIHomeViewModel.Item: IdentifiableType {
  
  public typealias Identity = String
  
  public var identity: Identity { componentViewModelItem.identity }
  
}

extension TKUIHomeViewModel.Section: AnimatableSectionModelType {
  
  public typealias Identity = String
  
  public init(original: TKUIHomeViewModel.Section, items: [TKUIHomeViewModel.Item]) {
    self = original
    self.items = items
  }
  
}
