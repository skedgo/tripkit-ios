//
//  TKUIAutocompletionViewModel+HomeCard.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 28/7/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension TKUIAutocompletionViewModel: TKUIHomeComponentViewModel {

  static func buildInstance(from inputs: TKUIHomeCard.ComponentViewModelInput) -> Self {
    return self.init(
      providers: TKUIHomeCard.config.autocompletionDataProviders ?? [],
      searchText: inputs.searchText,
      selected: inputs.itemSelected.compactMap { $0.componentViewModelItem as? TKUIAutocompletionViewModel.Item }.asSignal(onErrorSignalWith: .empty()),
      accessorySelected: inputs.itemAccessoryTapped.compactMap { $0.componentViewModelItem as? TKUIAutocompletionViewModel.Item }
    )
  }
  
  var homeCardSections: (Observable<Bool>) -> Observable<TKUIHomeViewModel.Section?> {
    return { searching in
      return Observable.combineLatest(self.sections.asObservable(), searching)
        .map { sections, searching in
          // FIXME: The number to show in home card should be user configurable
          let autocompletionItems = sections.flatMap { $0.items }
            .filter { item in
              // include everything when search is in progress
              guard !searching else { return true }
              
              // if there are no exceptions, include everything
              guard let include = TKUIHomeCard.config.inludeAutocompleterWhileSearchIsInactive else { return true }
              
              if let provider = item.provider { return include(provider) }
              else { return false }
            }
            .prefix(searching ? .max : 5)
        
          // Convert to a compatible home card item
          let homeCardItems = autocompletionItems.map(TKUIHomeViewModel.Item.init)
          
          // Place them into a compatible home card section
          let configuration = searching ? nil : TKUIHomeViewModel.Section.HeaderConfiguration(title: "Search history")
          return TKUIHomeViewModel.Section(identity: "single-autocomplete-section", items: homeCardItems, headerConfiguration: configuration)
        }
    }
  }
  
  var nextAction: Signal<TKUIHomeCardNextAction> {
    return selection.map { .selectOnMap($0) }
  }
  
  func cell(for item: TKUIHomeViewModel.Item, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell? {
    // We cannot handle non autocomplete items
    guard let autocompleteItem = item.componentViewModelItem as? TKUIAutocompletionViewModel.Item else { return nil }
    
    guard
      let cell = tableView.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: indexPath) as? TKUIAutocompletionResultCell
      else { assertionFailure("Unable to load an instance of TKUIAutocompletionResultCell"); return nil }
    
    cell.configure(with: autocompleteItem)    
    return cell
  }
  
  func registerCell(with tableView: UITableView) {
    tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
  }

}
 
extension TKUIAutocompletionViewModel.Item: TKUIHomeComponentViewModelItem {
}
