//
//  TKAppleGeocoder.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

@available(iOS, introduced: 9.3, unavailable, renamed: "TKAppleGeocoder")
public typealias SGAppleGeocoder = TKAppleGeocoder

@available(iOS 9.3, *)
public class TKAppleGeocoder: NSObject {
  
  enum GeocoderError: Error {
    case unexpectedResult
    case noMatchingMapItemFound
  }
  
  private let completer: MKLocalSearchCompleter
  private var completerDelegate: LocalSearchCompleterDelegate!
  private var disposeBag: DisposeBag!
  
  public override init() {
    self.completer = MKLocalSearchCompleter()
    
    super.init()
    
    completer.filterType = .locationsOnly
  }
  
}

// MARK: Geocoding

@available(iOS 9.3, *)
extension TKAppleGeocoder: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
    
    let fullString = TKLocationHelper.expandAbbreviation(inAddressString: input)
    
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = fullString
    request.region = MKCoordinateRegion(mapRect)
    return MKLocalSearch(request: request).rx
      .start()
      .map { $0.map { TKNamedCoordinate($0, forInput: input, near: request.region) } }
  }
  
}

@available(iOS 9.3, *)
extension TKAppleGeocoder: SGGeocoder {
  
  public func geocodeString(_ inputString: String, nearRegion mapRect: MKMapRect, success: @escaping SGGeocoderSuccessBlock, failure: SGGeocoderFailureBlock? = nil) {
    disposeBag = DisposeBag()
    geocode(inputString, near: mapRect)
      .subscribe(onSuccess: { results in
        success(inputString, results)
      }, onError: { error in
        failure?(inputString, error)
      })
      .disposed(by: disposeBag)
  }
  
}

// MARK: - Autocompletion

@available(iOS 9.3, *)
extension TKAppleGeocoder: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[TKAutocompletionResult]> {
    completerDelegate = LocalSearchCompleterDelegate()
    completer.delegate = completerDelegate
    completer.region = MKCoordinateRegion(mapRect)
    completer.queryFragment = input
    return completerDelegate.results
      .map { $0.enumerated().map { TKAutocompletionResult($1, forInput: input, index: $0) } }
      .take(1)
      .asSingle()
  }
  
  public func annotation(for result: TKAutocompletionResult) -> Single<MKAnnotation> {
    guard let completion = result.object as? MKLocalSearchCompletion else {
      return Single.error(GeocoderError.unexpectedResult)
    }
    let request = MKLocalSearch.Request(completion: completion)
    return MKLocalSearch(request: request).rx
      .start()
      .map {
        if let first = $0.first {
          return TKNamedCoordinate(first)
        } else {
          throw TKAppleGeocoder.GeocoderError.noMatchingMapItemFound
        }
      }
  }
  
}

// MARK: - Helpers

@available(iOS 9.3, *)
fileprivate class LocalSearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
  
  let results = PublishSubject<[MKLocalSearchCompletion]>()
  
  func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    results.onNext(completer.results)
  }
  
  func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
    results.onNext([])
  }
  
}

@available(iOS 9.3, *)
extension TKAutocompletionResult {
  
  convenience init(_ completion: MKLocalSearchCompletion, forInput input: String, index: Int) {
    self.init()
    object = completion
    title = completion.title
    subtitle = completion.subtitle
    image = TKAutocompletionResult.image(forType: .pin)
    
    score = Int(TKGeocodingResultScorer.calculateScore(title: title, subtitle: subtitle, searchTerm: input, minimum: 15, maximum: 65)) - index
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

extension Reactive where Base: MKLocalSearch {
  
  public func start() -> Single<[MKMapItem]> {
    return Single.create { subscriber in
      self.base.start { results, error in
        if let error = error {
          subscriber(.error(error))
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

