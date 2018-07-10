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

extension SGGeocoder where Self: TKGeocoding {

  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
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

extension TKBaseGeocoder: TKGeocoding { }
extension TKPeliasGeocoder: TKGeocoding { }
#if os(iOS)
  extension TKAddressBookManager: TKGeocoding { }
#endif


extension SGAutocompletionDataProvider where Self: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Observable<[TKAutocompletionResult]> {
    if let fast = self.autocompleteFast?(input, for: mapRect) {
      return Observable.just(fast)
    
    } else {
      return Observable.create { subscriber in
        self.autocompleteSlowly?(input, for: mapRect) { results in
          subscriber.onNext(results ?? [])
          subscriber.onCompleted()
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
  public func additionalAction(for presenter: UIViewController) -> (String, Single<Bool>)? {
    guard let title = self.additionalActionString?(), let handler = (self as SGAutocompletionDataProvider).additionalAction else { return nil }
    
    let action = Single<Bool>.create { subscriber in
      handler(presenter) { refresh in
        subscriber(.success(refresh))
      }
      return Disposables.create()
    }
    return (title, action)
  }
  #endif
  
}

extension TKSkedGoGeocoder: TKAutocompleting { }
extension TKCalendarManager: TKAutocompleting { }
extension TKFoursquareGeocoder: TKAutocompleting { }
extension TKRegionAutocompleter: TKAutocompleting { }
extension TKPeliasGeocoder: TKAutocompleting { }
#if os(iOS)
  extension TKAddressBookManager: TKAutocompleting { }
#endif
