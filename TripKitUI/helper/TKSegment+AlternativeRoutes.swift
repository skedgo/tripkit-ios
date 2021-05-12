//
//  TKSegment+AlternativeRoutes.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31.12.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKSegment {
 
  func insertRequestStartingHere() -> TripRequest {
    guard
      let start = start,
      start.coordinate.isValid,
      let moc = trip.managedObjectContext
      else { preconditionFailure() }
    
    let departure = TKNamedCoordinate.namedCoordinate(for: start)
    return TripRequest.insert(
      from: departure, to: trip.request.toLocation,
      for: departureTime, timeType: .leaveAfter,
      into:moc
    )
  }
}
