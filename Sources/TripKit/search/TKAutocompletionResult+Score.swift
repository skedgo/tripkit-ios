//
//  TKAutocompletionResult+Score.swift
//  TripKit
//
//  Created by Adrian Schönig on 18/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(MapKit)

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
  
  public struct Score: ExpressibleByIntegerLiteral {
    public let score: Int
    public var ranges: [NSRange] = []

    public init(score: Int, ranges: [NSRange] = []) {
      self.score = score
      self.ranges = ranges
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
      self.score = value
    }
  }
  
  public struct ScoreHighlights {
    public init(score: Int, titleHighlight: [NSRange] = [], subtitleHighlight: [NSRange] = []) {
      self.score = score
      self.titleHighlight = titleHighlight
      self.subtitleHighlight = subtitleHighlight
    }
    
    public let score: Int
    public var titleHighlight: [NSRange] = []
    public var subtitleHighlight: [NSRange] = []
  }
  
  /// 0:   not match, e.g., we're missing a word
  /// 25:  same words but wrong order
  /// 33:  has all target words but missing a completed one
  /// 50:  matches somewhere in the word
  /// 66:  contains all words in right order
  /// 75:  matches start of word in search term (but starts don't match)
  /// 100: exact match at start
  public static func nameScore(searchTerm fullTarget: String, candidate fullCandidate: String) -> Score {
    let target = stringForScoring(fullTarget)
    let candidate = stringForScoring(fullCandidate)
    
    if target.isEmpty {
      return candidate.isEmpty ? 100 : 0
    }
    if candidate.isEmpty {
      return 100 // having typed yet means a perfect match of everything you've typed so far
    }
    
    if target == candidate {
      return .init(score: 100, ranges: [.init(location: 0, length: candidate.utf8.count)])
    }
    
    if target.isAbbreviation(for: candidate) || target.isAbbreviation(for: stringForScoring(fullCandidate, removeBrackets: true)) {
      return 95
    }

    if candidate.isAbbreviation(for: target) || candidate.isAbbreviation(for: stringForScoring(fullTarget, removeBrackets: true)) {
      return 90
    }
    
    func nsRange(of string: String) -> NSRange? {
      let haystack = fullCandidate.lowercased()
      let needle = string.lowercased()
      let range = (haystack as NSString).range(of: needle)
      return  range.location == NSNotFound ? nil : range
    }
    
    // exact phrase matches
    let excess = candidate.utf8.count - target.utf8.count
    if let range = candidate.range(of: target) {
      if range.lowerBound == candidate.startIndex {
        // matches right at start
        return .init(score: score(100, penalty: excess, min: 75), ranges: [nsRange(of: target)].compactMap({$0}))
      }
      
      let before = candidate[candidate.index(before: range.lowerBound)]
      if before.isWhitespace {
        // matches beginning of word
        let offset = candidate.distance(from: candidate.startIndex, to: range.lowerBound)
        return .init(score: score(75, penalty: offset * 2 + excess, min: 33), ranges: [nsRange(of: target)].compactMap({$0}))
        
      } else {
        // in-word match
        return .init(score: score(25, penalty: excess, min: 5), ranges: [nsRange(of: target)].compactMap({$0}))
      }
    }
    
    // non-subscring matches
    let targetWords = target.components(separatedBy: " ")
    var lastMatch: String.Index = candidate.startIndex
    var ranges: [NSRange] = []
    for word in targetWords {
      if let match = candidate.range(of: word) {
        if let nsRange = nsRange(of: word) {
          ranges.append(nsRange)
        }
        
        if match.lowerBound >= lastMatch {
          // still in order, keep going
          lastMatch = match.lowerBound
        } else {
          // wrong order, abort with penalty
          return .init(score: score(10, penalty: excess, min: 0), ranges: ranges)
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
          return .init(score: score(33, penalty: excess, min: 10), ranges: ranges)
        }
      }
    }
    
    return .init(score: score(66, penalty: excess, min: 40), ranges: ranges)
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

#endif
