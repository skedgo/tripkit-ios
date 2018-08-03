//
//  TKUIResultsViewModel+State.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.08.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKUIResultsViewModel {
  
  private struct RestorationInfo: Codable {
    let requestID: String
  }
  
  static func save(request: TripRequest?) -> Data? {
    guard let request = request else { return nil }
    let state = RestorationInfo(requestID: request.persistentId())
    return try? PropertyListEncoder().encode(state)
  }
  
  static func restore(from data: Data?) -> TripRequest? {
    guard
      let data = data,
      let state = try? PropertyListDecoder().decode(RestorationInfo.self, from: data)
      else { return nil }

    return TripRequest(fromPersistentId: state.requestID, in: TripKit.shared.tripKitContext)
  }
  
}
