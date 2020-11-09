//
//  SGDeprecatedAutocompletionDataProvider+TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public enum TKGeocodingBackwardscompatibilityError: Error {
  case unknownError
  case couldNotCreateAnnotation
}

extension SGDeprecatedAutocompletionDataProvider where Self: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    if let fast = autocompleteFast?(input, for: mapRect) {
      completion(.success(fast))
    
    } else {
      autocompleteSlowly?(input, for: mapRect) { results in
        completion(.success(results ?? []))
      }
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    if let annotation = self.annotation?(for: result) {
      completion(.success(annotation))
    } else {
      completion(.failure(TKGeocodingBackwardscompatibilityError.couldNotCreateAnnotation))
    }
  }
  
  #if os(iOS) || os(tvOS)
  public func additionalActionTitle() -> String? {
    return self.additionalActionString?()
  }
  
  public func triggerAdditional(presenter: UIViewController, completion: @escaping (Bool) -> Void) {
    guard let handler = additionalAction else { assertionFailure(); return }
    handler(presenter, completion)
  }
  #endif
  
}

extension TKSkedGoGeocoder: TKAutocompleting { }
extension TKFoursquareGeocoder: TKAutocompleting { }
extension TKRegionAutocompleter: TKAutocompleting { }
