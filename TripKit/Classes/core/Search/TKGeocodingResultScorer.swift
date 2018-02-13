//
//  TKGeocodingResultScorer.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class TKGeocodingResultScorer: NSObject {

  private override init() {
  }
  
  @objc(calculateScoreForAnnotation:searchTerm:nearRegion:allowLongDistance:minimum:maximum:)
  public static func calculateScore(for annotation: MKAnnotation, searchTerm: String, near region: MKCoordinateRegion, allowLongDistance: Bool, minimum: UInt, maximum: UInt) -> UInt {
    
    guard let title = (annotation.title ?? nil) else {
      return 0
    }
    
    let titleScore = SGAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchTerm, candidate: title)
    let addressScore: UInt
    if let subtitle = (annotation.subtitle ?? nil) {
      addressScore = SGAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchTerm, candidate: subtitle)
    } else {
      addressScore = 0
    }
    let stringScore = max(titleScore, addressScore)
    
    let distanceScore = SGAutocompletionResult.scoreBasedOnDistance(from: annotation.coordinate, to: region, longDistance: allowLongDistance)
    
    let rawScore = (stringScore * 3 + distanceScore) / 4
    return SGAutocompletionResult.rangedScore(forScore: rawScore, betweenMinimum: minimum, andMaximum: maximum)
  }
  
}
