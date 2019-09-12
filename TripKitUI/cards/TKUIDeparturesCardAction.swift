//
//  TKUIDeparturesCardAction.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public protocol TKUIDeparturesCardAction {

  /// Title (and accessory label) of the button
  var title: String { get }
  
  /// Icon to display as the action. Should be a template image.
  var icon: UIImage { get }
  
  var style: TKUICardActionStyle { get }

  /// Handler executed when user taps on the button, providing the
  /// corresponding card and model instance. Should return whether the button
  /// should be refreshed as its title or icon changed as a result (e.g., for
  /// toggle actions such as adding or removing a reminder or favourite).
  ///
  /// Parameters are the card, the model instance, and the sender
  var handler: (TKUIDeparturesCard, [TKUIStopAnnotation], UIView) -> Bool { get }

}

public extension TKUIDeparturesCardAction {
  var style: TKUICardActionStyle { .normal }
}

