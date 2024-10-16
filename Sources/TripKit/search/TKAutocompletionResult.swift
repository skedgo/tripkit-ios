//
//  TKAutocompletionResult.swift
//  TripKit
//
//  Created by Adrian Schönig on 18/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct TKAutocompletionResult {
  public init(object: AnyHashable, title: String, titleHighlightRanges: [NSRange] = [], subtitle: String? = nil, subtitleHighlightRanges: [NSRange] = [], image: TKImage, accessoryButtonImage: TKImage? = nil, accessoryAccessibilityLabel: String? = nil, score: Int = 0, isInSupportedRegion: Bool = true) {
    self.object = object
    self.title = title
    self.titleHighlightRanges = titleHighlightRanges
    self.subtitle = subtitle
    self.subtitleHighlightRanges = subtitleHighlightRanges
    self.image = image
    self.accessoryButtonImage = accessoryButtonImage
    self.accessoryAccessibilityLabel = accessoryAccessibilityLabel
    self.isInSupportedRegion = isInSupportedRegion
    self.score = score
  }
  
  public weak var provider: AnyObject? = nil
  
  public let object: AnyHashable
  
  public let title: String
  
  public var titleHighlightRanges: [NSRange] = []
  
  public var subtitle: String? = nil
  
  public var subtitleHighlightRanges: [NSRange] = []
  
  public let image: TKImage
  
  public var accessoryButtonImage: TKImage? = nil
  
  public var accessoryAccessibilityLabel: String? = nil
  
  public var isInSupportedRegion: Bool = true
  
  /// A score of how this result should be ranked between 0 and 100
  ///
  /// 0: probably not a good result
  /// 25: matches only in secondary information
  /// 50: an average match
  /// 75: an good result matching the user input w
  /// 100: this gotta be what the user wanted!
  public var score: Int = 0
  
}

extension TKAutocompletionResult: Equatable {
  public static func == (lhs: TKAutocompletionResult, rhs: TKAutocompletionResult) -> Bool {
    lhs.provider === rhs.provider && lhs.object == rhs.object
  }
}

extension TKAutocompletionResult: Hashable {
  public func hash(into hasher: inout Hasher) {
    if let provider {
      hasher.combine("\(provider)")
    }
    hasher.combine(object)
  }
}

extension TKAutocompletionResult: Comparable {
  public static func < (lhs: TKAutocompletionResult, rhs: TKAutocompletionResult) -> Bool {
    if lhs.score == rhs.score {
      return lhs.title < rhs.title
    } else {
      return lhs.score >= rhs.score // Yes, highest score first
    }
  }
}

