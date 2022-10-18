//
//  TKAutocompletionResult+Score.swift
//  TripKit
//
//  Created by Adrian Schönig on 18/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

extension TKAutocompletionResult {
  
  public static func distanceScore(from coordinate: CLLocationCoordinate2D, to region: MKCoordinateRegion, longDistance: Bool) -> Int {
    let world = MKCoordinateRegion(.world)
    if abs(world.span.latitudeDelta - region.span.latitudeDelta) < 1, abs(world.span.longitudeDelta - region.span.longitudeDelta) < 1 {
      return 100
    }

    if region.contains(coordinate) {
      return 100
    }
    
    guard let distanceToCenter = coordinate.distance(from: region.center) else {
      return 0
    }
    
    let zeroScoreDistance: CLLocationDistance = longDistance ? 20_000_000 : 25_000
    if distanceToCenter > zeroScoreDistance {
      return 0
    }
    
    let match = longDistance ? sqrt(distanceToCenter / zeroScoreDistance) : distanceToCenter / zeroScoreDistance
    let proportion = 1.0 - match
    return Int(proportion * 100)
  }
  
  /// 0:   not match, e.g., we're missing a word
  /// 25:  same words but wrong order
  /// 33:  has all target words but missing a completed one
  /// 50:  matches somewhere in the word
  /// 66:  contains all words in right order
  /// 75:  matches start of word in search term (but starts don't match)
  /// 100: exact match at start
  public static func nameScore(searchTerm fullTarget: String, candidate fullCandidate: String) -> Int {
    let target = stringForScoring(fullTarget)
    let candidate = stringForScoring(fullCandidate)
    
    if target.isEmpty {
      return candidate.isEmpty ? 100 : 0
    }
    if candidate.isEmpty {
      return 100 // having typed yet means a perfect match of everything you've typed so far
    }
    
    if target == candidate {
      return 100
    }
    
    if target.isAbbreviation(for: candidate) || target.isAbbreviation(for: stringForScoring(fullCandidate, removeBrackets: true)) {
      return 95
    }

    if candidate.isAbbreviation(for: target) || candidate.isAbbreviation(for: stringForScoring(fullTarget, removeBrackets: true)) {
      return 90
    }
    
    let excess = candidate.utf8.count - target.utf8.count
    if let range = candidate.range(of: target) {
      if range.lowerBound == candidate.startIndex {
        // matches right at start
        return score(100, penalty: excess, min: 75)
      }
      
      let before = candidate[candidate.index(before: range.lowerBound)]
      if before.isWhitespace {
        // matches beginning of word
        let offset = candidate.distance(from: candidate.startIndex, to: range.lowerBound)
        return score(75, penalty: offset * 2 + excess, min: 33)
        
      } else {
        // in-word match
        return score(25, penalty: excess, min: 5)
      }
    }
    
    // non-subscring matches
    let targetWords = target.components(separatedBy: " ")
    var lastMatch: String.Index = candidate.startIndex
    for word in targetWords {
      if let match = candidate.range(of: word) {
        if match.lowerBound >= lastMatch {
          // still in order, keep going
          lastMatch = match.lowerBound
        } else {
          // wrong order, abort with penalty
          return score(10, penalty: excess, min: 0)
        }
        
      } else {
        // missing a word
        return 0
      }
    }
    
    // contains all target words in order
    // do we have all the finished words
    // (we ignore the last one here as you
    // might still be typing it).
    for word in targetWords.dropLast() {
      guard let range = candidate.range(of: word) else {
        assertionFailure()
        return 0
      }
      
      if range.upperBound < candidate.index(before: candidate.endIndex) {
        let after = candidate[range.upperBound]
        if after.isWhitespace {
          // full word match, continue with next
        } else {
          // candidate doesn't have a completed word
          return score(33, penalty: excess, min: 10)
        }
      }
    }
    
    return score(66, penalty: excess, min: 40)
  }
  
  private static func score(_ maximum: Int, penalty: Int, min: Int) -> Int {
    if penalty > maximum - min {
      return min
    } else {
      return maximum - penalty
    }
  }
  
  public static func rangedScore(for score: Int, min: Int, max: Int) -> Int {
    let range = Double(max - min)
    let percentage = Double(score) / 100
    return Int(percentage * range) + min
  }
  
  static func stringForScoring(_ candidate: String, removeBrackets: Bool = false) -> String {
    var adjusted: String
    if removeBrackets {
      do {
        adjusted = try NSRegularExpression(pattern: "(.*)\\(.*\\)").stringByReplacingMatches(
          in: candidate,
          range: .init(location: 0, length: (candidate as NSString).length),
          withTemplate: "$1"
        )
      } catch {
        assertionFailure()
        adjusted = candidate
      }
    } else {
      adjusted = candidate
    }
    
    return adjusted
      .reduce(into: "") { acc, character in
        if character.isLetter || character.isNumber {
          acc.append(character.lowercased())
        } else if character.isWhitespace, acc.last?.isWhitespace != true {
          acc.append(character)
        }
      }
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
  
}

fileprivate extension MKCoordinateRegion {
  func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
       coordinate.latitude <= center.latitude + span.latitudeDelta / 2
    && coordinate.latitude >= center.latitude - span.latitudeDelta / 2
    && coordinate.longitude <= center.longitude + span.longitudeDelta / 2
    && coordinate.longitude >= center.longitude - span.longitudeDelta / 2
  }
}

fileprivate extension String {
  func isAbbreviation(for longer: String) -> Bool {
    guard utf8.count > 2 else {
      return false
    }
    
    let abbreviated = longer.components(separatedBy: " ")
      .compactMap(\.first)
      .map(String.init)
      .joined()
    return lowercased() == abbreviated.lowercased()
  }
}
