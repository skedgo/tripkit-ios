//
//  TKAggregateGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import RxSwift

@available(*, unavailable, renamed: "TKAggregateGeocoder")
typealias SGAggregateGeocoder = TKAggregateGeocoder

public class TKAggregateGeocoder: NSObject {

  public let geocoders: [TKGeocoding]
  
  private var disposeBag: DisposeBag!
  
  public init(geocoders: [TKGeocoding]) {
    self.geocoders = geocoders
  }
}

extension TKAggregateGeocoder: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[SGKNamedCoordinate]> {

    let queries = geocoders.map { $0.geocode(input, near: mapRect).asObservable() }
    return Observable
      .merge(queries)
      .filter { !$0.isEmpty }
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
