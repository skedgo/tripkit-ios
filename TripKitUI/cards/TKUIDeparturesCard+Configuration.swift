//
//  TKUIDeparturesCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

public typealias TKUIDeparturesCardAction = TKUICardAction<TKUIDeparturesCard, [TKUIStopAnnotation]>

public extension TKUIDeparturesCard {
  
  /// Configurtion of any `TKUIDeparturesCard`. Use this to add custom
  /// actions.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUIDeparturesCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    /// Set this to add a list of action buttons to a departures card.
    ///
    /// Called when a departures card gets presented.
    public var departuresActionsFactory: (([TKUIStopAnnotation]) -> [TKUIDeparturesCardAction])?

  }
  
}
