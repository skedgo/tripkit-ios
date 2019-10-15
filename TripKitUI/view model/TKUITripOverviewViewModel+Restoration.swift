//
//  TKUITripOverviewViewModel+Restoration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.08.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKUITripOverviewViewModel {
  
  private struct RestorationInfo: Codable {
    let tripID: String
  }
  
  static func save(trip: Trip?) -> Data? {
    guard let trip = trip else { return nil }
    let state = RestorationInfo(tripID: trip.persistentId())
    return try? PropertyListEncoder().encode(state)
  }
  
  static func restore(from data: Data?) -> Trip? {
    guard
      let data = data,
      let state = try? PropertyListDecoder().decode(RestorationInfo.self, from: data)
      else { return nil }
    
    return Trip(fromPersistentId: state.tripID, in: TripKit.shared.tripKitContext)
  }
  
}
