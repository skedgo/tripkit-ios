//
//  TKUISegmentDirectionCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension TKUISegmentDirectionsCard {
  
  typealias Action = TKUICardAction<TKUISegmentDirectionsCard, TKSegment>
  
  /// Configurtion of any `TKUISegmentDirectionCard`. Use this to add
  /// custom actions.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUISegmentDirectionCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    // MARK: - Customising direction view actions
    
    /// Set this to add a list of action buttons to a direction card.
    ///
    /// Called when a direction card gets presented.
    public var actionFactory: ((TKSegment) -> [Action])?
  }
  
}
