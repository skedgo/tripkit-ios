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
  func autocomplete(_ text: Observable<(String, forced: Bool)>, mapRect: MKMapRect) -> Observable<[TKAutocompletionResult]> {
    
    return text
      .distinctUntilChanged( { $0.0 == $1.0 && $0.1 == $1.1} )
      .throttle(.milliseconds(200), latest: true, scheduler: MainScheduler.asyncInstance)
      .flatMapLatest { input -> Observable<[TKAutocompletionResult]> in
        let autocompletions = self.map { provider in
          provider
            .autocomplete(input.0, near: mapRect)
            .map { results -> [TKAutocompletionResult] in
              results.forEach { $0.provider = provider as AnyObject }
              return results
            }
            .asObservable()
            .startWith([])
          }
        
        if input.forced {
          return Observable.combineLatest(autocompletions).map { $0.flatMap { $0 } }
        } else {
          return Observable.stableRace(autocompletions)
        }
      }
  }
  
}

extension ObservableType {

  static func stableRace<Collection: Swift.Collection>(_ collection: Collection, cutOff: RxTimeInterval = .milliseconds(250), fastSpots: Int = 2, comparer: @escaping (Self.Element, Self.Element) -> Bool) -> Observable<[Self.Element]>
    where Collection.Element: Observable<[Self.Element]>, Element: Equatable {

      // Structure:
      // 1. The race winners, gets to take up to fast spots; this is done
      //    by taking from them until the timeout fires.
      // 2. In parallel, we wait for everyone to complete and merge all their
      //    results.
      // 3. The resulting stream is 2 if they complete before the timeout fires
      //    OR first 1 and then 2 but moving the items in 1 to the front.
      //    => This means that if 2 fires before 1, then we only take 2
      
      let observables = collection
        .map { $0.catchErrorJustReturn([]) }
      
      let merged = Observable.merge(observables)
        .scan(into: []) { $0.append(contentsOf: $1) }
        .map { $0.sorted(by: comparer) }
        .share()
      
      // ... This represents 1.: What are the best X results when the timer first?
      let timeOut = Observable<Int>.timer(cutOff, scheduler: SharingScheduler.make())
      let fast = merged
        .takeUntil(timeOut)
        .takeLast(1)
        .map { Array($0.prefix(fastSpots)) }
      
      // ... This represents 2.: What are all the results at the end?
      let all = merged.takeLast(1)

      // This combines 1 + 2
      let fastThenAll = Observable<[Element]>
        .combineLatest(fast, all.startWith([])) { first, all in
          if all.isEmpty {
            return first
          } else {
            let second = all.filter { !first.contains($0) }
            assert(second.count + first.count == all.count)
            return first + second
          }
        }
        .filter { !$0.isEmpty }
      
      // This either takes 1+2 or just 2 if the results come in before the timeout
      return Observable.amb([all, fastThenAll])
  }
  
  static func stableRace<Collection: Swift.Collection>(_ collection: Collection, cutOff: RxTimeInterval = .milliseconds(250), fastSpots: Int = 2) -> Observable<[Element]>
    where Collection.Element: Observable<[Element]>, Element: Comparable {
      return stableRace(collection, cutOff: cutOff, fastSpots: fastSpots, comparer: <)
  }
  
}

extension TKAutocompletionResult: Comparable {
  public static func < (lhs: TKAutocompletionResult, rhs: TKAutocompletionResult) -> Bool {
    return lhs.compare(rhs) == .orderedAscending
  }
}
