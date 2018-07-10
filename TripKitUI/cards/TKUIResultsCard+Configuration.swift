//
//  TKUIResultsCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension TKUIResultsCard {
  
  /// Configurtion of any `TKUIResultsCard`.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUIResultsCard.config`.
  public struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    /// Set this to have a button on the results card that is shown when the
    /// user tried to query for a from/to pair that isn't supported yet.
    ///
    /// Called when the user taps the button.
    public var requestRoutingSupport: ((TKUIResultsCard, TripRequest) -> Void)?
  }

}
