//
//  TKGeocoding+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TripKit

public extension TKGeocoding {
  
  /// Called to geocode a particular input.
  ///
  /// - Parameters:
  ///   - input: Query typed by the user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  /// - Returns: Single-observable with the geocoding results for the query.
  @available(*, deprecated, message: "Use async/await instead.")
  func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
    return Single.create { subscriber in
      self.geocode(input, near: mapRect) { result in
        switch result {
        case .success(let coordinates):
          subscriber(.success(coordinates))
        case .failure(let error):
          subscriber(.failure(error))
        }
      }
      return Disposables.create()
    }
  }
  
  @available(*, deprecated, message: "Use async/await instead.")
  func geocode(_ object: TKGeocodable, near region: MKMapRect) -> Single<Void> {
    return TKGeocoderHelper.rx.geocode(object, using: self, near: region)
  }
}

public extension TKAutocompleting {
  
  /// Called whenever a user types a character. You can assume this is already throttled.
  ///
  /// - Parameters:
  ///   - input: Query fragment typed by user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  /// - Returns: Autocompletion results for query fragment. Should fire with empty result or error out if nothing found. Needs to complete.
  func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[TKAutocompletionResult]> {
    return Single.create { subscriber in
      self.autocomplete(input, near: mapRect) { result in
        switch result {
        case .success(let results):
          subscriber(.success(results))
        case .failure(let error):
          subscriber(.failure(error))
        }
      }
      return Disposables.create {
        self.cancelAutocompletion()
      }
    }
  }
  
  /// Called to fetch the annotation for a previously returned autocompletion result
  ///
  /// - Parameter result: The result for which to fetch the annotation
  /// - Returns: Single-observable with the annotation for the result. Can error out if an unknown
  ///     result was passed in.
  func annotation(for result: TKAutocompletionResult) -> Single<MKAnnotation?> {
    return Single.create { subscriber in
      self.annotation(for: result) { result in
        switch result {
        case .success(let annotation):
          subscriber(.success(annotation))
        case .failure(let error):
          subscriber(.failure(error))
        }
      }
      return Disposables.create()
    }
  }
  
  func triggerAdditional(presenter: UIViewController) -> Single<Bool> {
    return Single.create { subscriber in
      self.triggerAdditional(presenter: presenter) { refresh in
        subscriber(.success(refresh))
      }
      return Disposables.create()
    }

  }

}

public extension Reactive where Base == TKGeocoderHelper {
  
  @available(*, deprecated, message: "Use async/await instead.")
  static func geocode(_ object: TKGeocodable, using geocoder: TKGeocoding, near region: MKMapRect) -> Single<Void> {
    return Single.create { subscriber in
      TKGeocoderHelper.geocode(object, using: geocoder, near: region) { result in
        switch result {
        case .success: subscriber(.success(()))
        case .failure(let error): subscriber(.failure(error))
        }
      }
      return Disposables.create()
    }
  }
  
}

// MARK: - Supercharging

public extension Array where Element == TKAutocompleting {
  
  /// Kicks off autocompletion that's monitoring the provided input string, and
  /// starts to autocomplete whenever the text is changing.
  ///
  /// - Parameters:
  ///   - text: Input text, which should fire when user enters text
  ///   - mapRect: Map rect to bias results towards, which should fire whenever map moves and
  ///     provide an initial value
  /// - Returns: Stream of autocompletion results. For each input change, it
  ///     can fire multiple times as more results are found by different
  ///     providers (i.e., elements in this array).
  func autocomplete(_ text: Observable<(String, forced: Bool)>, mapRect: Observable<MKMapRect>) -> Observable<[TKAutocompletionResult]> {
    
    return text
      .map { ($0.0 == Loc.CurrentLocation || $0.0 == Loc.Location) ? ("", forced: $0.1) : $0 }
      .distinctUntilChanged { (lhs: (String, forced: Bool), rhs: (String, forced: Bool)) -> Bool in
        lhs.0 == rhs.0 && lhs.forced == rhs.forced && !rhs.forced
      }
      .withLatestFrom(mapRect) { ($0, $1) }
      .debounce(.milliseconds(200), scheduler: MainScheduler.asyncInstance)
      .flatMapLatest { input, mapRect -> Observable<[TKAutocompletionResult]> in
        let autocompletions = self.map { provider in
          provider
            .autocomplete(input.0, near: mapRect)
            .catchAndReturn([])
            .map { results -> [TKAutocompletionResult] in
              return results.map {
                var updated = $0
                updated.provider = provider as AnyObject
                return updated
              }
            }
            .asObservable()
            .startWith([])
          }
        
        if input.forced {
          return Observable.combineLatest(autocompletions)
            .map { unsorted in
              unsorted.flatMap { $0 }.sorted(by: <)
            }
        } else {
          return Observable.stableRace(autocompletions)
        }
      }
  }
  
}

extension ObservableType {

  static func stableRace<Collection: Swift.Collection>(_ collection: Collection, cutOff: RxTimeInterval = .milliseconds(1000), fastSpots: Int = 3, comparer: @escaping (Self.Element, Self.Element) -> Bool) -> Observable<[Self.Element]>
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
        .map { $0.catchAndReturn([]) }
      
      let merged = Observable.merge(observables)
        .scan(into: []) { $0.append(contentsOf: $1) }
        .map { $0.sorted(by: comparer) }
        .share(replay: 1, scope: .forever)
      
      // ... This represents 1.: What are the best X results when the timer first?
      let timeOut = Observable<Int>.timer(cutOff, scheduler: SharingScheduler.make())
      let fast = merged
        .take(until: timeOut)
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
  
  static func stableRace<Collection: Swift.Collection>(_ collection: Collection, cutOff: RxTimeInterval = .milliseconds(1000), fastSpots: Int = 3) -> Observable<[Element]>
    where Collection.Element: Observable<[Element]>, Element: Comparable {
      return stableRace(collection, cutOff: cutOff, fastSpots: fastSpots, comparer: <)
  }
  
}

// MARK: - Helpers

extension Reactive where Base: MKLocalSearch {
  
  public func start() -> Single<[MKMapItem]> {
    return Single.create { subscriber in
      self.base.start { results, error in
        if let error = error {
          subscriber(.failure(error))
        } else {
          subscriber(.success(results?.mapItems ?? []))
        }
      }
      return Disposables.create {
        self.base.cancel()
      }
    }
  }
  
}


