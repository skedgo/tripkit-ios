//
//  TKRouteAutocompleter.swift
//  TripKit
//
//  Created by Adrian Schönig on 27/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

public class TKRouteAutocompleter: TKAutocompleting {
  public init() {
  }
  
  public var operatorID: String?
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
            TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: input, candidate: $0)
          }.max() ?? 0
        let score = TKAutocompletionResult.rangedScore(forScore: rawScore, betweenMinimum: 30, andMaximum: 80)
        return (route, score)
      }

      let results = scored.map { (route, score) -> TKAutocompletionResult in
        let result = TKAutocompletionResult()
        result.object = route
        result.title = [route.shortName, route.routeName]
          .compactMap { $0 }
          .joined(separator: ": ")
        result.image = route.modeInfo.image(type: .listMainMode) ?? TKImage.iconModePublicTransport
        result.isInSupportedRegion = true
        result.score = Int(score)
        return result
      }
      
      completion(.success(results))
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    completion(.success(nil))
  }
  
}

