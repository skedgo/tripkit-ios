//
//  TKRouteAutocompleter.swift
//  TripKit
//
//  Created by Adrian Schönig on 27/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

/// An autocompleter for public transport routes in supported TripGo regions
///
/// Implements ``TKAutocompleting``, providing instances of ``TKAPI/Route`` in
/// ``TKAutocompletionResult/object``.
///
/// - warning: These autocompletion results cannot be turned into an `MKAnnotation`, and
///  the implementation of ``annotation(for:completion:)`` will therefore call its completion
///  handler with `nil`.
public class TKRouteAutocompleter: TKAutocompleting {
  public init() {
  }
  
  /// An optional operator ID to limit which routes are returned
  public var operatorID: String?
  
  /// An optional list of mode identifier to limit which routes are returned
  public var modes: [String] = []
  
  private var activeSearch: Task<Void, Never>? = nil
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    
    self.activeSearch?.cancel()
    
    let coordinateRegion = MKCoordinateRegion(mapRect)
    guard
      !input.isEmpty,
      let region = TKRegionManager.shared.localRegions(overlapping: coordinateRegion).first
    else {
      return completion(.success([]))
    }
    
    self.activeSearch = Task {
      let routes: [TKAPI.Route]
      do {
        routes = try await TKBuzzInfoProvider.fetchRoutes(forRegion: region, query: input, modes: modes, operatorID: operatorID)
        try Task.checkCancellation()
      } catch {
        return completion(.failure(error))
      }
      
      let scored = routes.map { route in
        let rawScore = [route.shortName, route.routeName]
          .compactMap { $0 }
          .map {
            TKAutocompletionResult.nameScore(searchTerm: input, candidate: $0)
          }.max() ?? 0
        let score = TKAutocompletionResult.rangedScore(for: rawScore, min: 30, max: 80)
        return (route, score)
      }

      let results = scored.map { (route, score) -> TKAutocompletionResult in
        let title = [route.shortName, route.routeName]
          .compactMap { $0 }
          .joined(separator: ": ")
        
        return TKAutocompletionResult(
          object: route,
          title: title,
          image: route.modeInfo.image(type: .listMainMode) ?? TKImage.iconModePublicTransport,
          score: score
        )
      }
      
      completion(.success(results))
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    completion(.success(nil))
  }
  
}

