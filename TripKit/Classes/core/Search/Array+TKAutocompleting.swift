//
//  Array+TKAutocompleting.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 05.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

public extension Array where Element == TKAutocompleting {
  
  /// Kicks off autocompletion that's monitoring the provided input string, and
  /// starts to autocomplete whenever the text is changing.
  ///
  /// - Parameters:
  ///   - text: Input text, which should fire when user enters text
  ///   - mapRect: Map rect to bias results towards
  /// - Returns: Stream of autocompletion results. For each input change, it
  ///     can fire multiple times as more results are found by different
  ///     providers (i.e., elements in this array).
  public func autocomplete(_ text: Observable<String>, mapRect: MKMapRect) -> Observable<[TKAutocompletionResult]> {
    
    return text
      .throttle(0.2, latest: true, scheduler: MainScheduler.asyncInstance)
      .flatMapLatest { input -> Observable<[TKAutocompletionResult]> in
        // For each provider, let them calculate the result, but make
        // sure we start with no results, so that the `combineLatest`
        // will fire ASAP.
        let observables = self.map { provider in
            provider.autocomplete(input, near: mapRect)
              .map { results -> [TKAutocompletionResult] in
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
  }
  
}
