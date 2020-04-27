//
//  TKUITripModeByModeCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public protocol TKUITripModeByModePageBuilder {
  
  /// - Parameters:
  ///   - segment: A segment to display in the mode-by-mode pager
  ///   - mapManager: The mode-by-mode pager's map manager
  /// - Returns: The cards to use for the provided segment, can be empty
  func cards(for segment: TKSegment, mapManager: TKUITripMapManager) -> [(TGCard, TKUISegmentMode)]
  
  /// Each segment should have an identifier that changes whenever the card's configuration
  /// changes for this segment. If you return a new identifier for the same segment, the mode-by-mode
  /// cards will be rebuilt.
  ///
  /// - Parameter segment: A segment to display in the mode-by-mode pager
  /// - Returns: An identifier for the segment, should be non-nil if there's a card for it
  func cardIdentifier(for segment: TKSegment) -> String?
  
}

open class TKUIDefaultPageBuilder: TKUITripModeByModePageBuilder {
  
  public init() {}
  
  open func cards(for segment: TKSegment, mapManager: TKUITripMapManager) -> [(TGCard, TKUISegmentMode)] {
    if segment.order != .regular {
      return []
    } else if TKUISegmentDirectionsCard.canShowInstructions(for: segment) {
      return [(TKUISegmentDirectionsCard(for: segment, mapManager: mapManager), .onSegment)]
    } else {
      return [(TKUISegmentInstructionCard(for: segment, mapManager: mapManager), .onSegment)]
    }
  }
  
  open func cardIdentifier(for segment: TKSegment) -> String? {
    return segment.selectionIdentifier
  }
}


extension TKUITripModeByModeCard {
  
  /// Configurtion of any `TKUITripModeByModeCard`. Use this to determine how
  /// each page is built.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUITripModeByModeCard.config`.
  public struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    /// Builder used when initiallty constructing a `TKUITripModeByModeCard`
    /// to determine what page cards to use.
    public var builder: TKUITripModeByModePageBuilder = TKUIDefaultPageBuilder()
  }
  
}
