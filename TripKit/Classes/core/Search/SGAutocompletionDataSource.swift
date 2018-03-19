//
//  SGAutocompletionDataSource.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

extension SGAutocompletionDataSource {
  
  public convenience init(autocompleters: [TKAutocompleting]) {
    let storage = SGAutocompletionDataSourceSwiftStorage()
    storage.providers = autocompleters
    
    self.init(storage: storage)
  }
  
  @objc
  @available(*, deprecated: 9.3, message: "Use `init(autocompleters:)` instead")
  public convenience init(dataProviders: [SGAutocompletionDataProvider]) {
    let autocompleters = dataProviders.flatMap { $0 as? TKAutocompleting }
    self.init(autocompleters: autocompleters)
  }
  
  @objc
  func prepareForNewSearch() {
    storage.disposeBag = DisposeBag()
    
    // When the input is changing, update the results
    storage.inputText
       .asObservable()
      .throttle(0.2, scheduler: MainScheduler.asyncInstance)
      .flatMapLatest { input -> Observable<[SGAutocompletionResult]> in
        // For each provider, let them calculate the result, but make
        // sure we start with no results, so that the `combineLatest`
        // will fire ASAP.
        let observables = self.storage.providers
          .map { provider in
            provider.autocomplete(input, near: self.storage.mapRect)
              .asObservable()
              .map { results -> [SGAutocompletionResult] in
                results.forEach { $0.provider = provider as AnyObject }
                return results
              }
              .startWith([])
              .catchErrorJustReturn([])
          }
        return Observable
          .combineLatest(observables) { $0.flatMap { $0 } }
          .map { $0.sorted { $0.compare($1) == .orderedAscending }}
      }
      .throttle(0.5, scheduler: MainScheduler.asyncInstance)
      .bind(to: storage.results)
      .disposed(by: storage.disposeBag)
    
    // Start again with empty input
    storage.inputText.value = ""
  }
  
  /// Kicks off autocompletion. If it found something interesting, it'll
  /// call the completion handler, telling the caller whether to trigger
  /// a refresh of whatever this data source provides data for.
  ///
  /// - Parameters:
  ///   - input: Search string
  ///   - mapRect: Map rect to limit search to
  ///   - completion: Called when autocompletion results are loaded
  @objc(autocomplete:forMapRect:completion:)
  public func autocomplete(_ input: String, for mapRect: MKMapRect, completion: @escaping (Bool) -> Void) {
    
    storage.inputText.value = input
    
    storage.results
      .asDriver()
      .drive(onNext: { results in
        completion(true)
      })
      .disposed(by: storage.disposeBag)
  }
  
  @objc
  var startedTyping: Bool {
    return !storage.inputText.value.isEmpty
  }
  
  @objc
  var autocompletionResults: [SGAutocompletionResult] {
    return storage.results.value
  }

  @objc
  var additionalActions : [String] {
    return providers.flatMap { $0.additionalActionString }
  }
  
  @objc(performAdditionalActionAtIndex:completion:)
  func performAdditionalAction(at index: Int, completion: @escaping (Bool) -> Void) {
    let candidates = providers.filter { $0.additionalActionString != nil }
    candidates[index].performAdditionalAction(completion: completion)
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

  fileprivate let inputText = Variable<String>("")

  fileprivate var mapRect = MKMapRectNull
  
  // Outputs
  
  fileprivate var results = Variable<[SGAutocompletionResult]>([])

  // Helpers
  
  fileprivate var disposeBag = DisposeBag()
  
}
