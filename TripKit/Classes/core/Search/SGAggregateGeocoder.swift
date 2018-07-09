//
//  TKAggregateGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import RxSwift

@available(*, unavailable, renamed: "TKAggregateGeocoder")
public typealias SGAggregateGeocoder = TKAggregateGeocoder

public class TKAggregateGeocoder: NSObject {

  public let geocoders: [TKGeocoding]
  
  private var disposeBag: DisposeBag!
  
  public init(geocoders: [TKGeocoding]) {
    self.geocoders = geocoders
  }
}

extension TKAggregateGeocoder: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[SGKNamedCoordinate]> {

    let queries = geocoders.map {
      $0.geocode(input, near: mapRect)
        .asObservable()
        .catchErrorJustReturn([]) // Individual failures shouldn't terminate the sequence
    }
    return Observable
      .combineLatest(queries) {
        $0.reduce([]) { $0.mergeWithPreferences($1) }
      }
      .take(1)
      .asSingle()
  }

}

extension TKAggregateGeocoder: SGGeocoder {
  
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
