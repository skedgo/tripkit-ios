//
//  TKUIAutocompletionViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 05.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxDataSources
import RxCocoa
import RxSwift

class TKUIAutocompletionViewModel {
  
  struct Section {
    var items: [Item]
  }
  
  struct Item {
    fileprivate let index: Int
    fileprivate let completion: SGAutocompletionResult
    
    var image: UIImage { return completion.image }
    var title: String { return completion.title }
    var subtitle: String? { return completion.subtitle }
    var accessoryImage: UIImage? { return completion.accessoryButtonImage }
    var showFaded: Bool { return completion.isInSupportedRegion?.boolValue == false }
  }
  
  init(
    providers: [TKAutocompleting],
    searchText: Observable<String>,
    selected: Observable<Item>,
    accessorySelected: Observable<Item>,
    biasMapRect: MKMapRect = MKMapRectNull
    ) {
    
    sections = providers
      .autocomplete(searchText, mapRect: biasMapRect)
      .map { $0.buildSections() }
      .asDriver(onErrorDriveWith: Driver.empty())
    
    selection = selected
      .flatMapLatest { $0.completion.annotation }
      .asDriver(onErrorDriveWith: Driver.empty())
    
    accessorySelection = accessorySelected
      .flatMapLatest { $0.completion.annotation }
      .asDriver(onErrorDriveWith: Driver.empty())
  }
  
  let sections: Driver<[Section]>
  
  let selection: Driver<MKAnnotation>
  
  let accessorySelection: Driver<MKAnnotation>
}


// MARK: - Helpers

extension Array where Element == SGAutocompletionResult {
  
  fileprivate func buildSections() -> [TKUIAutocompletionViewModel.Section] {
    let items = enumerated().map { tuple in
      return TKUIAutocompletionViewModel.Item(index: tuple.offset, completion: tuple.element)
    }
    return [TKUIAutocompletionViewModel.Section(items: items)]
  }
  
}

extension SGAutocompletionResult {
  
  fileprivate var annotation: Single<MKAnnotation> {
    guard let provider = provider as? TKAutocompleting else {
      assertionFailure()
      return Single.error(NSError(code: 18376, message: "Bad provider!"))
    }
    return provider.annotation(for: self)
  }
  
}


// MARK: - RxDataSource protocol conformance

func == (lhs: TKUIAutocompletionViewModel.Item, rhs: TKUIAutocompletionViewModel.Item) -> Bool {
  guard lhs.title     == rhs.title      else { return false }
  guard lhs.subtitle  == rhs.subtitle   else { return false }
  return true
}

extension TKUIAutocompletionViewModel.Item: Equatable {
}

extension TKUIAutocompletionViewModel.Item: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    return "\(index)-\(title)"
  }
}

extension TKUIAutocompletionViewModel.Section: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = TKUIAutocompletionViewModel.Item
  
  init(original: TKUIAutocompletionViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity {
    return "Single section"
  }
}
