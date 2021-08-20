//
//  TKUIHomeCardCustomizationViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 18/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

class TKUIHomeCardCustomizationViewModel {
  
  init(items: [TKUIHomeCard.CustomizedItem],
       selected: Signal<Item>,
       moved: Signal<ItemMovedEvent>,
       done: Signal<Void>) {
    
    let modifiers = Signal<Modifier>.merge(
      selected.map { .selection($0) },
      moved.map { .move($0) }
    )
    
    let updatedItems =
      modifiers.scan(items, accumulator: Self.process)
        .startWith(items)
        .asObservable()
        .share(replay: 1, scope: .forever)
    
    sections = updatedItems
      .map { [Section(items: $0.map(Item.init))] }
      .asDriver(onErrorDriveWith: .empty())
    
    next = done
      .asObservable()
      .withLatestFrom(updatedItems) { Next.done($1) }
      .asSignal(onErrorSignalWith: .empty())
  }
    
  let sections: Driver<[Section]>
  
  let next: Signal<Next>
}

// MARK: - Content

extension TKUIHomeCardCustomizationViewModel {
  
  struct Section: Equatable {
    var items: [Item]
  }
  
  struct Item: Equatable {
    let identity: String
    let title: String
    let icon: UIImage
    let isEnabled: Bool
    
    init(_ customized: TKUIHomeCard.CustomizedItem) {
      self.identity = customized.id
      self.title = customized.item.name
      self.icon = customized.item.icon
      self.isEnabled = customized.isEnabled
    }
  }
  
  enum Next {
    case done([TKUIHomeCard.CustomizedItem])
  }
  
}

// MARK: - Interaction

extension TKUIHomeCardCustomizationViewModel {
  
  fileprivate enum Modifier {
    case selection(Item)
    case move(ItemMovedEvent)
  }
  
  private static func process(_ items: [TKUIHomeCard.CustomizedItem], move: Modifier) -> [TKUIHomeCard.CustomizedItem] {
    var updated = items
    
    switch move {
    case .move(let move):
      let item = updated.remove(at: move.sourceIndex.row)
      updated.insert(item, at: move.destinationIndex.row)
    case .selection(let selection):
      if let index = items.firstIndex(where: { $0.id == selection.identity}) {
        updated[index].isEnabled = !updated[index].isEnabled
      }
    }
    
    return updated
  }
  
}

// MARK: - RxDataSources

extension TKUIHomeCardCustomizationViewModel.Section: SectionModelType {
  init(original: Self, items: [TKUIHomeCardCustomizationViewModel.Item]) {
    self.items = items
  }
}
