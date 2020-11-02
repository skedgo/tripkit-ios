//
//  TKUIAutocompletionViewModel.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 05.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxCocoa
import RxSwift

class TKUIAutocompletionViewModel {
  
  struct Section {
    let identifier: String
    var items: [Item]
    let title: String?
  }
  
  enum Item {
    case currentLocation
    case autocompletion(AutocompletionItem)
    case action(ActionItem)
    
    fileprivate var result: TKAutocompletionResult? {
      switch self {
      case .autocompletion(let item): return item.completion
      case .action, .currentLocation: return nil
      }
    }
    
    fileprivate var annotation: Single<MKAnnotation>? {
      switch self {
      case .currentLocation: return .just(TKLocationManager.shared.currentLocation)
      case .autocompletion(let item): return item.completion.annotation
      case .action: return nil
      }
    }
    
    var provider: TKAutocompleting? {
      switch self {
      case .currentLocation: return nil
      case .autocompletion(let item): return item.provider
      case .action(let item): return item.provider
      }
    }
    
    var isAction: Bool {
      switch self {
      case .action: return true
      case .autocompletion, .currentLocation: return false
      }
    }
  }
  
  struct AutocompletionItem {
    let index: Int
    let completion: TKAutocompletionResult
    let includeAccessory: Bool
    
    var image: UIImage { completion.image }
    var title: String { completion.title }
    var subtitle: String? { completion.subtitle }
    var accessoryImage: UIImage? { includeAccessory ? completion.accessoryButtonImage : nil }
    var showFaded: Bool { completion.isInSupportedRegion?.boolValue == false }
    var provider: TKAutocompleting? { completion.provider as? TKAutocompleting }
  }
  
  struct ActionItem {
    fileprivate let provider: TKAutocompleting
    let title: String
    
    fileprivate init?(provider: TKAutocompleting) {
      guard let title = provider.additionalActionTitle() else { return nil }
      self.provider = provider
      self.title = title
    }
  }
  
  required init(
    providers: [TKAutocompleting],
    searchText: Observable<(String, forced: Bool)>,
    selected: Signal<Item>,
    accessorySelected: Signal<Item>? = nil,
    refresh: Signal<Void> = .never(),
    biasMapRect: Driver<MKMapRect> = .just(.null)
  ) {
    let errorPublisher = PublishSubject<Error>()
    
    sections = Self.buildSections(providers, searchText: searchText, refresh: refresh, biasMapRect: biasMapRect, includeAccessory: accessorySelected != nil)
      .asDriver(onErrorDriveWith: Driver.empty())
    
    selection = selected
      .compactMap(\.annotation)
      .asObservable()
      .flatMapLatest { fetched -> Observable<MKAnnotation> in
        return fetched
          .asObservable()
          .catchError { error in
            errorPublisher.onNext(error)
            return Observable.empty()
        }
      }
      .asSignal(onErrorSignalWith: .empty())
    
    accessorySelection = (accessorySelected  ?? .empty())
      .compactMap(\.result)
      .asObservable()
      .flatMapLatest { result -> Observable<MKAnnotation> in
        return result.annotation
          .asObservable()
          .catchError { error in
            errorPublisher.onNext(error)
            return Observable.empty()
        }
      }
      .asSignal(onErrorSignalWith: .empty())

    triggerAction = selected
      .filter(\.isAction)
      .compactMap(\.provider)
    
    error = errorPublisher.asSignal(onErrorSignalWith: .never())
  }
  
  let sections: Driver<[Section]>
  
  let selection: Signal<MKAnnotation>
  
  let accessorySelection: Signal<MKAnnotation>
  
  /// Fires when user taps on the "additional action" element of a `TKAutocompleting`
  /// provider. If that's the case, you should call `triggerAdditional` on it.
  let triggerAction: Signal<TKAutocompleting>
  
  let error: Signal<Error>
}


// MARK: - Helpers

extension TKUIAutocompletionViewModel {
  
  private static func buildSections(_ providers: [TKAutocompleting], searchText: Observable<(String, forced: Bool)>, refresh: Signal<Void>, biasMapRect: Driver<MKMapRect>, includeAccessory: Bool) -> Observable<[Section]> {
    
    let additionalItems = providers
      .compactMap(ActionItem.init)
      .map { Item.action($0) }
    let additionalSection = additionalItems.isEmpty ? [] : [Section(identifier: "actions", items: additionalItems, title: Loc.MoreResults)]
    
    let searchTrigger: Observable<MKMapRect>
      = Observable.combineLatest(
        refresh.asObservable().startWith(()),
        biasMapRect.asObservable()
      ) { $1 }

    return searchTrigger
      .flatMapLatest { providers.autocomplete(searchText, mapRect: $0) }
      .map { $0.buildSections(includeAccessory: includeAccessory) + additionalSection }
  }
  
}

extension Array where Element == TKAutocompletionResult {
  
  fileprivate func buildSections(includeAccessory: Bool) -> [TKUIAutocompletionViewModel.Section] {
    let items = enumerated().map { tuple -> TKUIAutocompletionViewModel.Item in
      let autocompletion = TKUIAutocompletionViewModel.AutocompletionItem(index: tuple.offset, completion: tuple.element, includeAccessory: includeAccessory)
      return .autocompletion(autocompletion)
    }
    
    if items.isEmpty {
      return [TKUIAutocompletionViewModel.Section(identifier: "current-location", items: [.currentLocation], title: nil)]
    } else {
      return [TKUIAutocompletionViewModel.Section(identifier: "results", items: items, title: nil)]
    }
  }
  
}

extension TKAutocompletionResult {
  
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
  switch (lhs, rhs) {
  case (.autocompletion(let left), .autocompletion(let right)): return left.completion == right.completion
  case (.action(let left), .action(let right)): return left.title == right.title
  case (.currentLocation, .currentLocation): return true
  default: return false
  }
}

extension TKUIAutocompletionViewModel.Item: Equatable {
}

extension TKUIAutocompletionViewModel.Item: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    switch self {
    case .currentLocation: return Loc.CurrentLocation
    case .action(let action): return action.title
    case .autocompletion(let autocompletion): return "\(autocompletion.index)-\(autocompletion.title)"
    }
  }
}

extension TKUIAutocompletionViewModel.Section: AnimatableSectionModelType {
  typealias Item = TKUIAutocompletionViewModel.Item
  
  init(original: TKUIAutocompletionViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
  
  var identity: String { identifier }
}
