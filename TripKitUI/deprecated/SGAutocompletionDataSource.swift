//
//  SGAutocompletionDataSource.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension SGAutocompletionDataSource {
  
  public convenience init(autocompleters: [TKAutocompleting]) {
    let storage = SGAutocompletionDataSourceSwiftStorage()
    storage.providers = autocompleters
    
    self.init(storage: storage)
  }
  
  @objc(prepareForNewSearchForMapRect:)
  public func prepareForNewSearch(for mapRect: MKMapRect) {
    storage.disposeBag = DisposeBag()
    
    // When the input is changing, update the results
    providers
      .autocomplete(storage.inputText.asObservable().map { ($0, forced: false) }, mapRect: mapRect)
      .bind(to: storage.results)
      .disposed(by: storage.disposeBag)
    
    // Start again with empty input
    storage.inputText.accept("")
    storage.mapRect = mapRect
  }
  
  /// Kicks off autocompletion. If it found something interesting,
  /// `autocompletionUpdated` will fire, so make sure you observe
  /// that.
  ///
  /// - Parameters:
  ///   - input: Search string
  public func autocomplete(_ input: String) {
    storage.inputText.accept(input)
  }
  
  public var autocompletionUpdated: Driver<Void> {
    return storage.results
      .asDriver()
      .map { _ in }
  }
  
  @objc
  public var startedTyping: Bool {
    return !storage.inputText.value.isEmpty
  }
  
  @objc
  public var autocompletionResults: [TKAutocompletionResult] {
    return storage.results.value
  }

  #if os(iOS) || os(tvOS)
  @objc(additionalActionsForPresenter:)
  public func additionalActions(for presenter: UIViewController) -> [String] {
    return providers.compactMap { $0.additionalActionTitle() }
  }
  #endif
  
}

// MARK: - Selections

extension SGAutocompletionDataSource {

  public enum Selection {
    case currentLocation
    case dropPin
    case refresh
    case searchForMore
    case autocompletion(MKAnnotation)
  }
  
  /// Call to figure out what action to perform when user taps soemthing
  ///
  /// - Parameter indexPath: Selected index path
  /// - Parameter refreshHandler: Called if a autocompletion provider requests an action
  /// - Returns: Action to perform. `nil` returned if nothing to do, in which case the refresh handler will be called.
  #if os(iOS) || os(tvOS)
  public func processSelection(indexPath: IndexPath, for presenter: UIViewController) -> Single<Selection> {
    return _processSelection(indexPath: indexPath, presenter: presenter)
  }
  #elseif os(OSX)
  public func processSelection(indexPath: IndexPath) -> Single<Selection> {
    return _processSelection(indexPath: indexPath, presenter: nil)
  }
  #endif

  private func _processSelection(indexPath: IndexPath, presenter: Any?) -> Single<Selection> {
    switch type(ofSection: indexPath.section) {
    case .sticky:
      switch stickyOption(at: indexPath) {
      case .currentLocation: return Single.just(.currentLocation)
      case .droppedPin: return Single.just(.dropPin)
      case .nextEvent, .unknown:
        assertionFailure("Unexpected sticky: \(indexPath)")
        return Single.just(.refresh)
      }
    
    case .autocompletion:
      if indexPath.item < autocompletionResults.count {
        let result = autocompletionResults[indexPath.item]
        guard let provider = result.provider as? TKAutocompleting else {
          assertionFailure("Couldn't get provider")
          return Single.just(.refresh)
        }
        return provider.annotation(for: result)
          .map { .autocompletion($0) }

      } else {
        assertionFailure("Invalid index path for autocompletion: \(indexPath)")
        return Single.just(.refresh)
      }
    
    case .more:
      switch extraRow(at: indexPath) {
      case .searchForMore: return Single.just(.searchForMore)
      
      case .provider:
        #if os(iOS) || os(tvOS)
        guard let controller = presenter as? UIViewController else {
          preconditionFailure()
        }

        let additionalRow = indexPath.item - 1 // subtract 'press search for more'
        let actions = providers.compactMap { $0.triggerAdditional(presenter: controller) }
        guard additionalRow >= 0 && additionalRow < actions.count else {
          assertionFailure("Invalid index path for extras: \(indexPath)")
          return Single.just(.refresh)
        }
        return actions[additionalRow].map { _ in .refresh }

        #elseif os(OSX)
        assertionFailure("This should not be available on macOS")
        return Single.just(.refresh)
        #endif
      }
    }
  }
  
}

// MARK: - Internal helpers

extension SGAutocompletionDataSource {
  private var providers: [TKAutocompleting] { return self.storage.providers }
}

@objc(SGAutocompletionDataSourceSwiftStorage)
class SGAutocompletionDataSourceSwiftStorage: NSObject {

  // Inputs
  
  fileprivate var providers: [TKAutocompleting] = []

  fileprivate let inputText = BehaviorRelay<String>(value: "")

  fileprivate var mapRect = MKMapRect.null
  
  // Outputs
  
  fileprivate var results = BehaviorRelay<[TKAutocompletionResult]>(value: [])

  // Helpers
  
  fileprivate var disposeBag = DisposeBag()
  
}