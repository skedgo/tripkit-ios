//
//  TKUIDeparturesCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

public protocol TKUIDeparturesCardAction {

  /// Title (and accessory label) of the button
  var title: String { get }
  
  /// Icon to display as the action. Should be a template image.
  var icon: UIImage { get }
  
  /// Handler executed when user taps on the button, providing the
  /// corresponding card and model instance. Should return whether the button
  /// should be refreshed as its title or icon changed as a result (e.g., for
  /// toggle actions such as adding or removing a reminder or favourite).
  ///
  /// Parameters are the card, the model instance, and the sender
  var handler: (TKUIDeparturesCard, [TKUIStopAnnotation], UIView) -> Bool { get }

}

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
