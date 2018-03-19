//
//  SGAutocompletionDataProvider+TKGeocoding.swift
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

extension SGBaseGeocoder: TKGeocoding {

  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[SGKNamedCoordinate]> {
    return Single.create { subscriber in
      self.geocodeString(
        input, nearRegion: mapRect,
        success: { (_, results) in
          subscriber(.success(results))
        },
        failure: { (_, error) in
          subscriber(.error(error ?? TKGeocodingBackwardscompatibilityError.unknownError))
        })
      return Disposables.create()
    }
  }
  
}


extension SGAutocompletionDataProvider where Self: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[SGAutocompletionResult]> {
    if let fast = self.autocompleteFast?(input, for: mapRect) {
      return Single.just(fast)
    
    } else {
      return Single.create { subscriber in
        self.autocompleteSlowly?(input, for: mapRect) { results in
          subscriber(.success(results ?? []))
        }
        return Disposables.create()
      }
    }
  }
  
  public func annotation(for result: SGAutocompletionResult) -> Single<MKAnnotation> {
    if let annotation = self.annotation?(for: result) {
      return Single.just(annotation)
    } else {
      return Single.error(TKGeocodingBackwardscompatibilityError.couldNotCreateAnnotation)
    }
  }
  
  public var additionalActionString: String? {
    return self.additionalActionString?()
  }
  
  public func performAdditionalAction(completion: @escaping (Bool) -> Void) {
    self.additionalAction?(completion)
  }
  
}

extension SGAddressBookManager: TKAutocompleting { }
extension SGBuzzGeocoder: TKAutocompleting { }
extension SGCalendarManager: TKAutocompleting { }
extension SGFoursquareGeocoder: TKAutocompleting { }
extension SGRegionAutocompleter: TKAutocompleting { }
extension TKPeliasGeocoder: TKAutocompleting { }

