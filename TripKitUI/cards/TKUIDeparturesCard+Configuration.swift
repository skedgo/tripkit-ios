//
//  TKUIDeparturesCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

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

    /// Set this to true if the services' transit icons should get the colour
    /// of the respective line.
    ///
    /// Default to `false`.
    public var colorCodeTransitIcons: Bool = false
  }
  
}
