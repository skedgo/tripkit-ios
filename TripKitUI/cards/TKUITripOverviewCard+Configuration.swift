//
//  TKUITripOverviewCardConfiguration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension TKUITripOverviewCard {
  
  public struct Configuration {
    private init() {}
    
    public static let empty = Configuration()
    
    public var presentSegmentHandler: ((TKUITripOverviewCard, TKSegment) -> Void)?
    
    public var presentAttributionHandler: ((TKUITripOverviewCard, URL) -> Void)?
    
    public var startTripHandler: ((TKUITripOverviewCard, Trip) -> Void)?
  }
  
}
