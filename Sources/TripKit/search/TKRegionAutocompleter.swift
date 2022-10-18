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
      .flatMap { region -> [(TKRegion.City, score: Int)] in
        if input.isEmpty {
          return region.cities.map { ($0, 100) }
        } else {
          return region.cities.compactMap { city in
            guard let name = city.title else { return nil }
            let titleScore = TKAutocompletionResult.nameScore(searchTerm: input, candidate: name)
            guard titleScore > 0 else { return nil }
            let distanceScore = TKAutocompletionResult.distanceScore(from: city.coordinate, to: .init(mapRect), longDistance: true)
            let rawSore = (titleScore * 9 + distanceScore) / 10
            let score = TKAutocompletionResult.rangedScore(for: rawSore, min: 10, max: 70)
            return (city, score)
          }
        }
      }
    
    let image = TKAutocompletionResult.image(for: .city)
    let results = scoredMatches.map { tuple -> TKAutocompletionResult in
      return TKAutocompletionResult(
        object: tuple.0,
        title: tuple.0.title!, // we filtered those out without a name
        image: image,
        score: tuple.score
      )
    }
    
    completion(.success(results))
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    let city = result.object as! TKRegion.City
    completion(.success(city))
  }
  
}
