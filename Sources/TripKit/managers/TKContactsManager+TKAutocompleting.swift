//
//  TKContactsManager+TKAutocompleting.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

extension TKContactsManager {
  
  private func fetchContacts(searchString: String, kind: TKContactsManager.AddressKind? = nil, completion: @escaping (Result<[TKContactsManager.ContactAddress], Error>) -> Void) {
    queue.async {
      completion(Result {
        try self.fetchContacts(searchString: searchString, kind: kind)
      })
    }
  }
  
}

// MARK: - TKAutocompleting

extension TKContactsManager: TKAutocompleting {
  
  public var allowLocationInfoButton: Bool { false }
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    
    guard !input.isEmpty else {
      completion(.success([]))
      return
    }
    
    fetchContacts(searchString: input) { result in
      completion(result.map {
        $0.map { $0.toResult(provider: self, search: input) }
      })
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    guard let contact = result.object as? TKContactsManager.ContactAddress else {
      preconditionFailure("Unexpected object. We require `result.object` to be `TKContactsManager.ContactAddress`, but got: \(result.object)")
    }
    
    Self.geocode(contact) { result in
      completion(result.map { $0 as MKAnnotation })
    }
  }
  
#if os(iOS) || os(tvOS) || os(visionOS)
  @objc
  public func additionalActionTitle() -> String? {
    if isAuthorized { return nil }
    
    return NSLocalizedString("Include contacts", tableName: "Shared", bundle: .tripKit, comment: "Button to include contacts in search, too.")
  }
  
  public func triggerAdditional(presenter: UIViewController, completion: @escaping (Bool) -> Void) {
    tryAuthorization(in: presenter, completion: completion)
  }
#endif
  
  private static func geocode(_ contact: ContactAddress, completion: @escaping (Result<TKNamedCoordinate, Error>) -> Void) {
    let geocoder = CLGeocoder()
    geocoder.geocodePostalAddress(contact.postalAddress) { placemarks, error in
      if let match = placemarks?.first {
        let result = TKNamedCoordinate(placemark: match)
        result.name = contact.locationName
        completion(.success(result))
      } else {
        completion(.failure(error ?? TKGeocoderHelper.errorForNoLocationFound(forInput: contact.address)))
      }
    }
  }
}

extension TKContactsManager.ContactAddress {
  fileprivate func toResult(provider: TKAutocompleting, search: String) -> TKAutocompletionResult {
    var result = TKAutocompletionResult(
      object: self,
      title: locationName,
      subtitle: address,
      image: image ?? TKAutocompletionResult.image(for: .contact)
    )

    let nameScore = TKAutocompletionResult.nameScore(searchTerm: search, candidate: name)
    let addressScore = TKAutocompletionResult.nameScore(searchTerm: search, candidate: address)
    let textScore = min(100, (nameScore + addressScore) / 2)
    result.score = Int(TKAutocompletionResult.rangedScore(for: textScore, min: 50, max: 90))
    
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

extension TKContactsManager: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    guard !input.isEmpty else {
      completion(.success([]))
      return
    }
    
    func geocodeNext(in contacts: [TKContactsManager.ContactAddress], soFar: [TKNamedCoordinate]) {
      if let next = contacts.first {
        Self.geocode(next) { result in
          var acc = soFar
          if let next = try? result.get() {
            acc.append(next)
          }
          geocodeNext(in: Array(contacts.dropFirst()), soFar: acc)
        }
      } else {
        completion(.success(soFar))
      }
    }
    
    fetchContacts(searchString: input) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let contacts):
        geocodeNext(in: contacts, soFar: [])
      }
    }
  }
  
}
