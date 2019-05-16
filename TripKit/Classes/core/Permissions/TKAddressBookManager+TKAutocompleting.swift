//
//  TKAddressBookManager+TKAutocompleting.swift
//  TripKit
//
//  Created by Adrian Schönig on 16.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

#if os(iOS)

extension Optional {
  
  func orThrow(_ error: Error) throws -> Wrapped {
    switch self {
    case .none: throw error
    case .some(let wrapped): return wrapped
    }
  }
  
}

extension TKAutocompleting {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
    return autocomplete(input, near: mapRect)
      .map { try $0.first.orThrow(TKAddressBookManager.AutocompletionError.couldNotResolveAddress) }
      .flatMap { self.annotation(for: $0) }
      .map { try TKNamedCoordinate.namedCoordinate(for: $0).orThrow(TKAddressBookManager.AutocompletionError.couldNotResolveAddress)
      }
      .map { [$0] }
  }
  
}

extension TKAddressBookManager: TKGeocoding {}
extension TKPeliasGeocoder: TKGeocoding {}

extension TKAddressBookManager: TKAutocompleting {
  
  enum AutocompletionError: Error {
    case unexpectedObject
    case couldNotResolveAddress
    case featureNotAvailable
  }
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[TKAutocompletionResult]> {
    guard !input.isEmpty else { return .just([]) }
    
    return Single.create { [weak self] subscriber in
      guard let self = self else { return Disposables.create() }
      
      self.fetchContacts(for: input, of: .unknown) { _, addresses in
        let results = addresses.map { dict -> TKAutocompletionResult in
          let result = TKAutocompletionResult(addressDict: dict as! [String : Any], search: input)
          result.provider = self
          return result
        }
        subscriber(.success(results))
      }
      
      return Disposables.create()
    }
  }
  
  public func annotation(for result: TKAutocompletionResult) -> Single<MKAnnotation> {

    guard #available(iOS 9.3, *) else {
      return .error(AutocompletionError.featureNotAvailable)
    }
    
    let geocoder = helperGeocoder as? TKAppleGeocoder ?? TKAppleGeocoder()
    helperGeocoder = geocoder
    
    guard let dict = result.object as? [String: Any] else {
      return .error(AutocompletionError.unexpectedObject)
    }
    
    let named = TKNamedCoordinate(
      name: dict[kBHKeyForRecordName] as? String,
      address: dict[kBHKeyForRecordAddress] as? String
    )
    
    return geocoder.geocode(named, near: .world)
        .map { _ in named } // TODO: Only if success
  }
  
  public func additionalActionTitle() -> String? {
    if isAuthorized() { return nil }
    
    return NSLocalizedString("Include contacts", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Include contacts.")
  }
  
  public func triggerAdditional(presenter: UIViewController) -> Single<Bool> {
    return Single.create { subscriber in
      self.tryAuthorizationForSender(nil, in: presenter) {
        subscriber(.success($0))
      }
      return Disposables.create()
    }
  }
  
}

// MARK: - Helpers

extension TKAutocompletionResult {
  
  fileprivate convenience init(addressDict: [String: Any], search: String) {
    self.init()
    
    object = addressDict
    title = addressDict[kBHKeyForRecordName] as! String
    subtitle = addressDict[kBHKeyForRecordAddress] as? String
    image = TKAutocompletionResult.image(forType: .contact)
    
    let nameScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: title)
    let addressScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: search, candidate: subtitle ?? "")
    let textScore = min(100, (nameScore + addressScore) / 2)
    
    score = Int(TKAutocompletionResult.rangedScore(forScore: textScore, betweenMinimum: 50, andMaximum: 90))
  }
  
}

#endif
