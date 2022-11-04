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

import TripKit

class TKUIAutocompletionViewModel {
  
  struct Section {
    let identifier: String
    var items: [Item]
    var title: String? = nil
  }
  
  enum Item: Equatable {
    case currentLocation
    case autocompletion(AutocompletionItem)
    case action(ActionItem)
    
    fileprivate var result: TKAutocompletionResult? {
      switch self {
      case .autocompletion(let item): return item.completion
      case .action, .currentLocation: return nil
      }
    }
    
    fileprivate var selection: Single<TKAutocompletionSelection>? {
      switch self {
      case .currentLocation: return .just(.annotation(TKLocationManager.shared.currentLocation))
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
  
  struct AutocompletionItem: Equatable {
    let index: Int
    let completion: TKAutocompletionResult
    let includeAccessory: Bool
    
    var image: UIImage { completion.image }
    var title: String { completion.title }
    var subtitle: String? { completion.subtitle }
    var accessoryAccessibilityLabel: String? { includeAccessory ? completion.accessoryAccessibilityLabel : nil }
    var accessoryImage: UIImage? { includeAccessory ? completion.accessoryButtonImage : nil }
    var showFaded: Bool { completion.isInSupportedRegion?.boolValue == false }
    var provider: TKAutocompleting? { completion.provider as? TKAutocompleting }
  }
  
  struct ActionItem: Equatable {
    static func == (lhs: TKUIAutocompletionViewModel.ActionItem, rhs: TKUIAutocompletionViewModel.ActionItem) -> Bool {
      lhs.title == rhs.title
    }
    
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
    includeCurrentLocation: Bool = false,
    searchText: Observable<(String, forced: Bool)>,
    selected: Signal<Item>,
    accessorySelected: Signal<Item>? = nil,
    refresh: Signal<Void> = .never(),
    biasMapRect: Driver<MKMapRect> = .just(.null)
  ) {
    let errorPublisher = PublishSubject<Error>()
    
    sections = Self.buildSections(providers, searchText: searchText, refresh: refresh, biasMapRect: biasMapRect, includeCurrentLocation: includeCurrentLocation, includeAccessory: accessorySelected != nil)
      .asDriver(onErrorDriveWith: Driver.empty())
    
    selection = selected
      .compactMap(\.selection)
      .asObservable()
      .flatMapLatest { fetched -> Observable<TKAutocompletionSelection> in
        return fetched
          .asObservable()
          .catch { error in
            errorPublisher.onNext(error)
            return Observable.empty()
        }
      }
      .asSignal(onErrorSignalWith: .empty())
    
    accessorySelection = (accessorySelected  ?? .empty())
      .compactMap(\.result)
      .asObservable()
      .flatMapLatest { result -> Observable<TKAutocompletionSelection> in
        return result.annotation
          .asObservable()
          .catch { error in
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
  
  let selection: Signal<TKAutocompletionSelection>
  
  let accessorySelection: Signal<TKAutocompletionSelection>
  
  /// Fires when user taps on the "additional action" element of a `TKAutocompleting`
  /// provider. If that's the case, you should call `triggerAdditional` on it.
  let triggerAction: Signal<TKAutocompleting>
  
  let error: Signal<Error>
}


// MARK: - Helpers

extension TKUIAutocompletionViewModel {
  
  private static func buildSections(_ providers: [TKAutocompleting], searchText: Observable<(String, forced: Bool)>, refresh: Signal<Void>, biasMapRect: Driver<MKMapRect>, includeCurrentLocation: Bool, includeAccessory: Bool) -> Observable<[Section]> {
    
    let additionalItems = providers
      .compactMap(ActionItem.init)
      .map { Item.action($0) }
    let additionalSection = additionalItems.isEmpty ? [] : [Section(identifier: "actions", items: additionalItems, title: Loc.MoreResults)]
    
    let searchTrigger = refresh.asObservable().startWith(())

    return searchTrigger
      .flatMapLatest { providers.autocomplete(searchText, mapRect: biasMapRect.asObservable()) }
      .map { $0.buildSections(includeCurrentLocation: includeCurrentLocation, includeAccessory: includeAccessory) + additionalSection }
  }
  
}

extension Array where Element == TKAutocompletionResult {
  
  fileprivate func buildSections(includeCurrentLocation: Bool, includeAccessory: Bool) -> [TKUIAutocompletionViewModel.Section] {
    var sections: [TKUIAutocompletionViewModel.Section] = []
    if includeCurrentLocation {
      sections.append(TKUIAutocompletionViewModel.Section(identifier: "current-location", items: [.currentLocation]))
    }

    let items = enumerated().map { tuple -> TKUIAutocompletionViewModel.Item in
      let autocompletion = TKUIAutocompletionViewModel.AutocompletionItem(index: tuple.offset, completion: tuple.element, includeAccessory: includeAccessory)
      return .autocompletion(autocompletion)
    }
    if !items.isEmpty {
      sections.append(TKUIAutocompletionViewModel.Section(identifier: "results", items: items))
    }

    return sections
  }
  
}

extension TKAutocompletionResult {
  
  fileprivate var annotation: Single<TKAutocompletionSelection> {
    guard let provider = provider as? TKAutocompleting else {
      assertionFailure()
      return Single.error(NSError(code: 18376, message: "Bad provider!"))
    }
    return provider.annotation(for: self)
      .map { [weak self] in
        if let annotation = $0 {
          return .annotation(annotation)
        } else if let self {
          return .result(self)
        } else {
          throw TKGeocoderHelper.GeocodingError.outdatedResult
        }
      }
  }
  
}


// MARK: - RxDataSource protocol conformance

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
