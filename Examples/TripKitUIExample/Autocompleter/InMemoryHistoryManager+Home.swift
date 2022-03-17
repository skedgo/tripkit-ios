//
//  InMemoryHistoryManager+Home.swift
//  TripKitUIExample
//
//  Created by Adrian Schönig on 17/3/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxCocoa
import TripKitUI

extension InMemoryHistoryManager.History: TKUIHomeComponentItem {
  var identity: String {
    "\(date)"
  }
}

extension InMemoryHistoryManager: TKUIHomeComponentViewModel {
  static func buildInstance(from inputs: TKUIHomeComponentInput) -> InMemoryHistoryManager {
    let manager = Self.shared
    manager.selection = inputs.itemSelected.compactMap { $0 as? History }
    return manager
  }
  
  var identity: String {
    return "home-history"
  }
  
  var homeCardSection: Driver<TKUIHomeComponentContent> {
    return history
      .asDriver(onErrorJustReturn: [])
      .map { items in
        TKUIHomeComponentContent(
          items: items,
          header: .init(
            title: "Search history",
            action: (
              "Clear all", {
                self.history.onNext([])
                return .success
              }
            )
          )
        )
      }
  }
  
  func cell(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell? {
    guard let history = item as? History else { return nil }
    let cell = tableView.dequeueReusableCell(withIdentifier: "home-history") ?? UITableViewCell(style: .default, reuseIdentifier: "home-history")
    cell.textLabel?.text = history.annotation.title ?? "Location"
    return cell
  }
  
  var nextAction: Signal<TKUIHomeCard.ComponentAction> {
    selection.map {
      .handleSelection($0.annotation, component: self)
    }
  }
  
  
}
