//
//  TKGeocoding.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation
import MapKit

public protocol TKGeocoding {
  
  /// Called to geocode a particular input.
  ///
  /// - Parameters:
  ///   - input: Query typed by the user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  ///   - completion: Handler with the geocoding results for the query.
  func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void)
}

public extension TKGeocoding {
  /// Called to geocode a particular input.
  ///
  /// - Parameters:
  ///   - input: Query typed by the user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  /// - Returns: Geocoding results for the query.
  func geocode(_ input: String, near mapRect: MKMapRect) async throws -> [TKNamedCoordinate] {
    try await withCheckedThrowingContinuation { continuation in
      geocode(input, near: mapRect) { result in
        continuation.resume(with: result)
      }
    }
  }
}

public protocol TKAutocompleting {
  
  /// Called whenever a user types a character. You can assume this is already throttled.
  ///
  /// - Parameters:
  ///   - input: Query fragment typed by user
  ///   - mapRect: Last map rect the map view was zoomed to (can be `MKMapRectNull`)
  ///   - completion: Handled called with the autocompletion results for query fragment. Should fire with empty result or error out if nothing found. Needs to be called, unless `cancelAutocompletion` was called.
  func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void)
  
  /// Called to fetch the annotation for a previously returned autocompletion result
  ///
  /// - Parameter result: The result for which to fetch the annotation
  /// - Parameter completion: Completion handler that's called with the annotation for the result, if representable as such. Called with `nil` if not representable, or can also be called with an error if it is representable but the conversion failed. Needs to be called.
  func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void)
  
  /// Called when previously requested autocompletion result is no longer relevant. Use this to clean
  /// up resources.
  func cancelAutocompletion()
  
  #if os(iOS) || os(tvOS)
  /// Text and action for an additional row to display in the results, e.g., to request
  /// user permissions if the autocompletion provider can't provide results without that.
  ///
  /// The `Single` should fire on completion of the action (e.g., asking for permission)
  /// indicating if the results or texts should be refreshed.
  func additionalActionTitle() -> String?
  
  func triggerAdditional(presenter: UIViewController, completion: @escaping (Bool) -> Void)
  
  #endif
  
  var allowLocationInfoButton: Bool { get }

}

public enum TKAutocompletionSelection {
  case annotation(MKAnnotation)
  case result(TKAutocompletionResult)
}

extension TKAutocompleting {
  
  public var allowLocationInfoButton: Bool { true }
  
  public func cancelAutocompletion() {}
  
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
