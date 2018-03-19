//
//  TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

public protocol TKGeocoding {
  
  func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[SGKNamedCoordinate]>
  
}

public protocol TKAutocompleting {
  
  func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[SGAutocompletionResult]>
  
  func annotation(for result: SGAutocompletionResult) -> Single<MKAnnotation>
  
  var additionalActionString: String? { get }
  
  func performAdditionalAction(completion: @escaping (Bool) -> Void)
  
}

extension TKAutocompleting {
  
  public var additionalActionString: String? { return nil }
  
  public func performAdditionalAction(completion: @escaping (Bool) -> Void) {
    completion(false)
  }
  
}
