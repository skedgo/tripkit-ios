//
//  TKUITableCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 12.08.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa
import TGCardViewController

open class TKUITableCard: TGTableCard {
  
  private let highlighted = PublishSubject<IndexPath>()

  open override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    
    #if targetEnvironment(macCatalyst)
    self.handleMacSelection = highlighted.onNext
    #else

    // LATER: Also apply this on Catalyst, once that supports iOS 15
    if #available(iOS 15, *), tableView.style == .plain {
      tableView.sectionHeaderTopPadding = 0.0
    }
    #endif
  }
  
  public func selectedIndex(in tableView: UITableView) -> Signal<IndexPath> {
    #if targetEnvironment(macCatalyst)
    return highlighted.asAssertingSignal()
    #else
    return tableView.rx.itemSelected.asSignal()
    #endif
  }
  
  public func selectedItem<Item, Section>(in tableView: UITableView, dataSource: TableViewSectionedDataSource<Section>) -> Signal<Item> where Section: SectionModelType, Item == Section.Item {
    selectedItemWithSender(in: tableView, dataSource: dataSource).map { $0.0 }
  }
  
  public func selectedItemWithSender<Item, Section>(in tableView: UITableView, dataSource: TableViewSectionedDataSource<Section>) -> Signal<(Item, sender: Any?)> where Section: SectionModelType, Item == Section.Item {
    
    selectedIndex(in: tableView)
      .map { (dataSource[$0], sender: tableView.cellForRow(at: $0)) }
  }
  
}
