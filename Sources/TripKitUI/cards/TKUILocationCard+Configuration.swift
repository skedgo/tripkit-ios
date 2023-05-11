//
//  TKUILocationCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 3/5/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

public extension TKUILocationCard {
  
  typealias Action = TKUICardAction<TKUILocationCard, TKNamedCoordinate>
  
  /// Configuration of any `TKUILocationCard`. Use this to add
  /// custom actions.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUILocationCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    // MARK: - Customising direction view actions
    
    /// Set this to add a list of action buttons to a direction card.
    ///
    /// Called when a direction card gets presented.
    public var actionFactory: ((TKNamedCoordinate) -> [Action])?
  }
  
}
