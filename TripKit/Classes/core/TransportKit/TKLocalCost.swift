//
//  TKLocalCost.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 23/11/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class TKLocalCost: NSObject, Codable {
  
  public let minCost: Double?
  public let maxCost: Double?
  public let cost: Double
  public let currency: String
  public let accuracy: TKLocalCostAccuracy
  
}

extension TKLocalCost {
  
  public static func newInstance(from json: [String: Any]?) -> TKLocalCost? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(TKLocalCost.self, withJSONObject: json)
  }
  
}

public enum TKLocalCostAccuracy: String {
  
  case internalEstimate = "internal_estimate"
  case externalEstimate = "external_estimate"
  case confirmed = "confirmed"
  
}

extension TKLocalCostAccuracy: Codable { }
