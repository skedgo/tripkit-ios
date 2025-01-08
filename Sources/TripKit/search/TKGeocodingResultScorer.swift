//
//  TKGeocodingResultScorer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

#if canImport(MapKit)

import Foundation
import MapKit

public class TKGeocodingResultScorer: NSObject {

  private override init() {
  }
  
  public static func calculateScore(for annotation: MKAnnotation, searchTerm: String, near region: MKCoordinateRegion, allowLongDistance: Bool, minimum: Int, maximum: Int) -> TKAutocompletionResult.ScoreHighlights {
    
    guard let title = (annotation.title ?? nil) else {
      return .init(score: 0)
    }
    
    let titleScore = TKAutocompletionResult.nameScore(searchTerm: searchTerm, candidate: title)
    let addressScore: TKAutocompletionResult.Score
    if let subtitle = (annotation.subtitle ?? nil) {
      addressScore = TKAutocompletionResult.nameScore(searchTerm: searchTerm, candidate: subtitle)
    } else {
      addressScore = 0
    }
    let stringScore = max(titleScore.score, addressScore.score)
    
    let distanceScore = TKAutocompletionResult.distanceScore(from: annotation.coordinate, to: region, longDistance: allowLongDistance)
    
    let rawScore = (stringScore + distanceScore) / 2
    let ranged = TKAutocompletionResult.rangedScore(for: rawScore, min: minimum, max: maximum)
    return .init(
      score: ranged,
      titleHighlight: titleScore.ranges,
      subtitleHighlight: addressScore.ranges
    )
  }
  
  public static func calculateScore(title: String, subtitle: String?, searchTerm: String, minimum: Int, maximum: Int) -> TKAutocompletionResult.ScoreHighlights {
    assert(maximum > minimum, "Order must be preserved.")
    
    let titleScore = TKAutocompletionResult.nameScore(searchTerm: searchTerm, candidate: title)
    let addressScore: TKAutocompletionResult.Score
    if let subtitle = subtitle {
      addressScore = TKAutocompletionResult.nameScore(searchTerm: searchTerm, candidate: subtitle)
    } else {
      addressScore = 0
    }
    let rawScore = max(titleScore.score, addressScore.score)

    let ranged = TKAutocompletionResult.rangedScore(for: rawScore, min: minimum, max: maximum)
    return .init(
      score: ranged,
      titleHighlight: titleScore.ranges,
      subtitleHighlight: addressScore.ranges
    )
  }
  
}

#endif
