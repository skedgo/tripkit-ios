//
//  TKUIServiceCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

public extension TKUIServiceCard {
  
  typealias EmbarkationPair = (embarkation: StopVisits, disembarkation: StopVisits?)
  
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    public var serviceActionsFactory: ((EmbarkationPair) -> [TKUICardAction<TKUIServiceCard, EmbarkationPair>])?
  }
  
}
