//
//  SGDeprecatedAutocompletionDataProvider+TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

public enum TKGeocodingBackwardscompatibilityError: Error {
  case unknownError
  case couldNotCreateAnnotation
}

extension SGDeprecatedAutocompletionDataProvider where Self: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[TKAutocompletionResult]> {
    if let fast = self.autocompleteFast?(input, for: mapRect) {
      return .just(fast)
    
    } else {
      return Single.create { subscriber in
        self.autocompleteSlowly?(input, for: mapRect) { results in
          subscriber(.success(results ?? []))
        }
        return Disposables.create()
      }
    }
  }
  
  public func annotation(for result: TKAutocompletionResult) -> Single<MKAnnotation> {
    if let annotation = self.annotation?(for: result) {
      return Single.just(annotation)
    } else {
      return Single.error(TKGeocodingBackwardscompatibilityError.couldNotCreateAnnotation)
    }
  }
  
  #if os(iOS) || os(tvOS)
  public func additionalActionTitle() -> String? {
    return self.additionalActionString?()
  }
  
  public func triggerAdditional(presenter: UIViewController) -> Single<Bool> {
    guard let handler = additionalAction else { assertionFailure(); return .never() }
    
    return Single.create { subscriber in
      handler(presenter) { refresh in
        subscriber(.success(refresh))
      }
      return Disposables.create()
    }
  }
  #endif
  
}

extension TKSkedGoGeocoder: TKAutocompleting { }
extension TKFoursquareGeocoder: TKAutocompleting { }
extension TKRegionAutocompleter: TKAutocompleting { }
