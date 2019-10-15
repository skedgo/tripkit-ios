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
    
    let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchTerm, candidate: title)
    let addressScore: UInt
    if let subtitle = (annotation.subtitle ?? nil) {
      addressScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchTerm, candidate: subtitle)
    } else {
      addressScore = 0
    }
    let stringScore = max(titleScore, addressScore)
    
    let distanceScore = TKAutocompletionResult.scoreBasedOnDistance(from: annotation.coordinate, to: region, longDistance: allowLongDistance)
    
    let rawScore = (stringScore + distanceScore) / 2
    return TKAutocompletionResult.rangedScore(forScore: rawScore, betweenMinimum: minimum, andMaximum: maximum)
  }
  
  public static func calculateScore(title: String, subtitle: String?, searchTerm: String, minimum: UInt, maximum: UInt) -> UInt {
    assert(maximum > minimum, "Order must be preserved.")
    
    let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchTerm, candidate: title)
    let addressScore: UInt
    if let subtitle = subtitle {
      addressScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: searchTerm, candidate: subtitle)
    } else {
      addressScore = 0
    }
    let rawScore = max(titleScore, addressScore)

    return TKAutocompletionResult.rangedScore(forScore: rawScore, betweenMinimum: minimum, andMaximum: maximum)
  }
  
}
