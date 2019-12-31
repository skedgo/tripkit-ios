//
//  TKSegment+AlternativeRoutes.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKSegment {
 
  public func insertRequestStartingHere() -> TripRequest {
    guard
      let start = start,
      let departure = TKNamedCoordinate.namedCoordinate(for: start),
      let moc = trip.managedObjectContext
      else { preconditionFailure() }
    
    return TripRequest.insert(
      from: departure, to: trip.request.toLocation,
      for: departureTime, timeType: .leaveAfter,
      into:moc
    )
  }
}
