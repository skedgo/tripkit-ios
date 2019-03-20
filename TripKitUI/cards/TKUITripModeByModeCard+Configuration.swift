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
  func cards(for segment: TKSegment, mapManager: TKUITripMapManager) -> [TGCard]
  
}

open class TKUIDefaultPageBuilder: TKUITripModeByModePageBuilder {
  
  public init() {}
  
  open func cards(for segment: TKSegment, mapManager: TKUITripMapManager) -> [TGCard] {
    if segment.order != .regular {
      return []
    } else if segment.isSelfNavigating {
      return [TKUISegmentDirectionsCard(for: segment, mapManager: mapManager)]
    } else {
      return [TKUISegmentInstructionCard(for: segment, mapManager: mapManager)]
    }
  }
}


public extension TKUITripModeByModeCard {
  
  
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
