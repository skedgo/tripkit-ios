//
//  TKAppleGeocoder.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation
import MapKit

@available(iOS, introduced: 9.3, unavailable, renamed: "TKAppleGeocoder")
public typealias SGAppleGeocoder = TKAppleGeocoder

public class TKAppleGeocoder: NSObject {
  
  enum GeocoderError: Error {
    case unexpectedResult
    case noMatchingMapItemFound
  }
  
  private let completer: MKLocalSearchCompleter
  private var completerDelegate: LocalSearchCompleterDelegate!
  
  public override init() {
    self.completer = MKLocalSearchCompleter()
    
    super.init()
  }
  
}

// MARK: Geocoding

extension TKAppleGeocoder: TKGeocoding {
  
  private static func expandAbbreviation(in address: String) -> String {
    // List of address words
    let replacement = [
      "(\\W)st(\\W|$)" : "$1Street ",
      "(\\W)pde(\\W|$)" : "$1Parade ",
      "(\\W)ally(\\W|$)" : "$1Alley ",
      "(\\W)arc(\\W|$)" : "$1Arcade ",
      "(\\W)ave(\\W|$)" : "$1Avenue ",
      "(\\W)bvd(\\W|$)" : "$1Boulevard ",
      "(\\W)cl(\\W|$)" : "$1Close ",
      "(\\W)cres(\\W|$)" : "$1Crescent ",
      "(\\W)dr(\\W|$)" : "$1Drive ",
      "(\\W)esp(\\W|$)" : "$1Esplanade ",
      "(\\W)hwy(\\W|$)" : "$1Highway ",
      "(\\W)pl(\\W|$)" : "$1Place ",
      "(\\W)rd(\\W|$)" : "$1Road ",
      "(\\W)sq(\\W|$)" : "$1Square ",
      "(\\W)tce(\\W|$)" : "$1Terrace ",
    ]
    
    var updated = address
    for entry in replacement {
      updated.replacingOccurrences(of: entry.key, with: entry.value, options: [.caseInsensitive, .regularExpression])
    }
    return updated
  }
  
  public func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    
    let fullString = Self.expandAbbreviation(in: input)
    
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = fullString
    request.region = MKCoordinateRegion(mapRect)
    
    MKLocalSearch(request: request).start { results, error in
      if let error = error {
        completion(.failure(error))
      } else {
        let mapItems = results?.mapItems ?? []
        let coordinates = mapItems.map { TKNamedCoordinate($0, forInput: input, near: request.region) }
        completion(.success(coordinates))
      }
    }
  }
  
}

// MARK: - Autocompletion

extension TKAppleGeocoder: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    
    completerDelegate = LocalSearchCompleterDelegate { results in
      completion(results.map {
        $0.enumerated().map { TKAutocompletionResult($1, forInput: input, index: $0) }
      })
    }
    
    completer.delegate = completerDelegate
    completer.region = MKCoordinateRegion(mapRect)
    completer.queryFragment = input
    
    if #available(iOS 13, macOS 10.15, *) {
      completer.resultTypes = [.address, .pointOfInterest]
    } else {
      completer.filterType = .locationsOnly
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    guard let searchCompletion = result.object as? MKLocalSearchCompletion else {
      completion(.failure(GeocoderError.unexpectedResult))
      return
    }
    let request = MKLocalSearch.Request(completion: searchCompletion)
    MKLocalSearch(request: request).start { results, error in
      if let error = error {
        completion(.failure(error))
      } else if let first = results?.mapItems.first {
        completion(.success(TKNamedCoordinate(first)))
      } else {
        completion(.failure(GeocoderError.noMatchingMapItemFound))
      }
    }
  }
  
}

// MARK: - Helpers

fileprivate class LocalSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
  
  let handler: (Result<[MKLocalSearchCompletion], Error>) -> Void
  
  init(handler: @escaping (Result<[MKLocalSearchCompletion], Error>) -> Void) {
    self.handler = handler
  }
  
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    handler(.success(completer.results))
  }
  
  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    handler(.failure(error))
  }
  
}

extension TKAutocompletionResult {
  
  convenience init(_ completion: MKLocalSearchCompletion, forInput input: String, index: Int) {
    self.init()
    object = completion
    title = completion.title
    subtitle = completion.subtitle
    image = TKAutocompletionResult.image(for: .pin)
    
    score = Int(TKGeocodingResultScorer.calculateScore(title: title, subtitle: subtitle, searchTerm: input, minimum: 25, maximum: 65)) - index
  }
  
}

extension TKNamedCoordinate {
  
  convenience init(_ mapItem: MKMapItem, forInput input: String? = nil, near region: MKCoordinateRegion? = nil) {
    self.init(placemark: mapItem.placemark)
    phone = mapItem.phoneNumber
    url = mapItem.url
    
    if let input = input, let region = region {
      sortScore = Int(TKGeocodingResultScorer.calculateScore(for: self, searchTerm: input, near: region, allowLongDistance: false, minimum: 15, maximum: 65))
    }
  }
  
}
