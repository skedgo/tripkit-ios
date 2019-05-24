//
//  TKUICardAction.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct TKUICardAction<Card, Model> {
  
  /// Title (and accessory label) of the button
  public let title: String
  
  /// Icon to display as the action. Should be a template image.
  public let icon: UIImage
  
  /// Handler executed when user taps on the button, providing the
  /// corresponding card and model instance. Should return whether the button
  /// should be refreshed as its title or icon changed as a result (e.g., for
  /// toggle actions such as adding or removing a reminder or favourite).
  ///
  /// Parameters are the card, the model instance, and the sender
  public let handler: (Card, Model, UIView) -> Bool

  public init(title: String, icon: UIImage, handler: @escaping (Card, Model, UIView) -> Bool) {
    self.title = title
    self.icon = icon
    self.handler = handler
  }
}
