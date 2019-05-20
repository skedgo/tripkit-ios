//
//  TKContactsManager+TKAutocompleting.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

import RxSwift

// MARK: - TKAutocompleting

@available(iOS 9.0, *)
extension TKContactsManager: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[TKAutocompletionResult]> {
    guard !input.isEmpty else { return .just([]) }
    
    return rx.fetchContacts(searchString: input)
      .map { $0.map { $0.toResult(provider: self, search: input) } }
  }
  
  public func annotation(for result: TKAutocompletionResult) -> Single<MKAnnotation> {
    guard let contact = result.object as? TKContactsManager.ContactAddress else {
      preconditionFailure("Unexpected object. We require `result.object` to be `TKContactsManager.ContactAddress`, but got: \(result.object)")
    }
    
    return TKContactsManager.geocode(contact).map { $0 as MKAnnotation }
  }
  
  private static func geocode(_ contact: ContactAddress) -> Single<TKNamedCoordinate> {
    if #available(iOS 11.0, *) {
      return Single.create { subscriber in
        var geocoder: CLGeocoder! = CLGeocoder()
        geocoder!.geocodePostalAddress(contact.postalAddress) { placemarks, error in
          if let match = placemarks?.first {
            let result = TKNamedCoordinate(placemark: match)
            result.name = contact.locationName
            subscriber(.success(result))
          } else {
            subscriber(.error(error ?? TKGeocoderHelper.errorForNoLocationFound(forInput: contact.address)))
          }
        }
        return Disposables.create {
          geocoder = nil
        }
      }
    } else {
      let named = TKNamedCoordinate(name: contact.name, address: contact.address)
      return TKGeocoderHelper.geocodeUsingPreferredGeocoder(named, near: .world).map { _ in named }
    }
  }
  
}

@available(iOS 9.0, *)
extension TKContactsManager.ContactAddress {
  fileprivate func toResult(provider: TKAutocompleting, search: String) -> TKAutocompletionResult {
    let result = TKAutocompletionResult()
    result.object = self
    result.title = locationName
    result.subtitle = address.replacingOccurrences(of: "\n", with: ", ")
    result.image = image ?? TKAutocompletionResult.image(forType: .contact)
    result.provider = provider as AnyObject
    
    let nameScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: name)
    let addressScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: address)
    let textScore = min(100, (nameScore + addressScore) / 2)
    result.score = Int(TKAutocompletionResult.rangedScore(forScore: textScore, betweenMinimum: 50, andMaximum: 90))
    
    return result
  }
}

extension Optional {
  
  func orThrow(_ error: Error) throws -> Wrapped {
    switch self {
    case .none: throw error
    case .some(let wrapped): return wrapped
    }
  }
  
}
// MARK: - TKGeocoding

@available(iOS 9.0, *)
extension TKContactsManager: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
    guard !input.isEmpty else { return .just([]) }
    
    return rx.fetchContacts(searchString: input)
      .asObservable()
      .flatMapLatest { contacts -> Observable<[TKNamedCoordinate]> in
        let geocoded = contacts.map { TKContactsManager.geocode($0).asObservable() }
        return Observable.combineLatest(geocoded)
      }
      .asSingle()
  }
  
}
