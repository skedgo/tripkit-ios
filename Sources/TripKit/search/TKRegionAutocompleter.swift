//
//  TKRegionAutocompleter.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

public class TKRegionAutocompleter: TKAutocompleting {
  public init() {
  }
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    
    let scoredMatches = TKRegionManager.shared.regions
      .flatMap { region -> [(TKRegion.City, score: UInt)] in
        if input.isEmpty {
          return region.cities.map { ($0, 100) }
        } else {
          return region.cities.compactMap { city in
            guard let name = city.title else { return nil }
            let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: input, candidate: name)
            guard titleScore > 0 else { return nil }
            let distanceScore = TKAutocompletionResult.scoreBasedOnDistance(from: city.coordinate, to: .init(mapRect), longDistance: true)
            let rawScore = (titleScore * 9 + distanceScore) / 10
            let score = TKAutocompletionResult.rangedScore(forScore: rawScore, betweenMinimum: 10, andMaximum: 70)
            return (city, score)
          }
        }
      }
    
    let image = TKAutocompletionResult.image(for: .city)
    let results = scoredMatches.map { tuple -> TKAutocompletionResult in
      let result = TKAutocompletionResult()
      result.object = tuple.0
      result.image = image
      result.title = tuple.0.title! // we filtered those out without a name
      result.provider = self
      result.isInSupportedRegion = true
      result.score = Int(tuple.score)
      return result
    }
    
    completion(.success(results))
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    let city = result.object as! TKRegion.City
    completion(.success(city))
  }
  
}
