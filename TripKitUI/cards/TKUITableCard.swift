//
//  TKUITableCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 12.08.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import TGCardViewController

import RxSwift
import RxCocoa
import RxDataSources

open class TKUITableCard: TGTableCard {
  
  private let highlighted = PublishSubject<IndexPath>()

  open override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    #if targetEnvironment(macCatalyst)
    self.handleMacSelection = highlighted.onNext
    #endif
  }
  
  public func selectedIndex(in tableView: UITableView) -> Signal<IndexPath> {
    #if targetEnvironment(macCatalyst)
    return highlighted.asSignal(onErrorSignalWith: .empty())
    #else
    return tableView.rx.itemSelected.asSignal()
    #endif
  }
  
  public func selectedItem<Item, Section>(in tableView: UITableView, dataSource: RxDataSources.TableViewSectionedDataSource<Section>) -> Signal<Item> where Section: SectionModelType, Item == Section.Item {
    selectedIndex(in: tableView).map { dataSource[$0] }
  }
  
}
