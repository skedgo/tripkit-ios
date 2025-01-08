//
//  TKRegionAutocompleter.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(MapKit)

import Foundation
import MapKit

/// An autocompleter for cities in supported TripGo regions
///
/// Implements ``TKAutocompleting``, providing instances of ``TKRegion/City`` in
/// ``TKAutocompletionResult/object``.
public class TKRegionAutocompleter: TKAutocompleting {
  public init() {
  }
  
  public var allowLocationInfoButton: Bool { false }
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    
    let cities = TKRegionManager.shared.regions.flatMap(\.cities)
    let maxScore = input.isEmpty ? 85 : 70
    
    guard !input.isEmpty || cities.count < 20 else {
      // If we show the default list with no input, don't spam it with lots of
      // cities if this app works everywhere.
      completion(.success([]))
      return
    }
    
    let scoredMatches = cities
      .compactMap { city -> (TKRegion.City, score: TKAutocompletionResult.ScoreHighlights)? in
        if input.isEmpty {
          return (city, .init(score: maxScore))
        } else {
          guard let name = city.title else { return nil }
          let titleScore = TKAutocompletionResult.nameScore(searchTerm: input, candidate: name)
          guard titleScore.score > 0 else { return nil }
          let distanceScore = TKAutocompletionResult.distanceScore(from: city.coordinate, to: .init(mapRect), longDistance: true)
          let rawScore = (titleScore.score * 9 + distanceScore) / 10
          let score = TKAutocompletionResult.rangedScore(for: rawScore, min: 10, max: maxScore)
          return (city, .init(score: score, titleHighlight: titleScore.ranges))
        }
      }
    
    let image = TKAutocompletionResult.image(for: .city)
    let results = scoredMatches.map { tuple -> TKAutocompletionResult in
      return TKAutocompletionResult(
        object: tuple.0,
        title: tuple.0.title!, // we filtered those out without a name
        titleHighlightRanges: tuple.score.titleHighlight,
        image: image,
        score: tuple.score.score
      )
    }
    
    completion(.success(results))
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    let city = result.object as! TKRegion.City
    completion(.success(city))
  }
  
}

#endif
