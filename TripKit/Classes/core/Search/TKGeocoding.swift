//
//  TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public protocol TKGeocoding {
  
  /// Called to geocode a particular input.
  ///
  /// - Parameters:
  ///   - input: Query typed by the user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  ///   - completion: Handler with the geocoding results for the query.
  func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void)
}

public protocol TKAutocompleting {
  
  /// Called whenever a user types a character. You can assume this is already throttled.
  ///
  /// - Parameters:
  ///   - input: Query fragment typed by user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  /// - Returns: Autocompletion results for query fragment. Should fire with empty result or error out if nothing found. Needs to complete.
  func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void)
  
  /// Called to fetch the annotation for a previously returned autocompletion result
  ///
  /// - Parameter result: The result for which to fetch the annotation
  /// - Returns: Single-observable with the annotation for the result. Can error out if an unknown
  ///     result was passed in.
  func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void)
  
  #if os(iOS) || os(tvOS)
  /// Text and action for an additional row to display in the results, e.g., to request
  /// user permissions if the autocompletion provider can't provide results without that.
  ///
  /// The `Single` should fire on completion of the action (e.g., asking for permission)
  /// indicating if the results or texts should be refreshed.
  func additionalActionTitle() -> String?
  
  func triggerAdditional(presenter: UIViewController, completion: @escaping (Bool) -> Void)
  
  #endif

}

extension TKAutocompleting {
  
  #if os(iOS) || os(tvOS)
  public func additionalActionTitle() -> String? {
    return nil
  }
  
  public func triggerAdditional(presenter: UIViewController, completion: (Bool) -> Void) {
    assertionFailure()
    completion(false)
  }
  #endif
  
}
