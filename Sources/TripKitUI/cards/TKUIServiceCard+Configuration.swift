//
//  TKUIServiceCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

public extension TKUIServiceCard {
  
  typealias EmbarkationPair = (embarkation: StopVisits, disembarkation: StopVisits?)
  
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    public var serviceActionsFactory: (@MainActor (EmbarkationPair) -> [TKUICardAction<TKUIServiceCard, EmbarkationPair>])?
    
    /// Used stand-alone or next to a description
    ///
    /// This is *not* a template image
    public var bicycleAccessibilityImage: UIImage = TripKitUIBundle.imageNamed("icon-bike-accessible-small")
    
    /// Used in trip segments view, as a miniature icon next to the vehicle
    ///
    /// This is a template image
    public var bicycleAccessibilityImageMini: UIImage = TripKitUIBundle.imageNamed("icon-bike-mini")
  }
  
}
