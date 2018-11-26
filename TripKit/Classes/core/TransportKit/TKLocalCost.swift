//
//  TKLocalCost.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 23/11/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// This class encapsulates information about the money cost of a trip segment.
public class TKLocalCost: NSObject, Codable {
  
  /// Minimum value when cost is specified as a range
  public let minCost: Double?
  
  /// Maximum value when cost is specified as a range
  public let maxCost: Double?
  
  /// Cost for a trip segment. This value considers the average value
  /// when the cost is specified as a range.
  public let cost: Double
  
  /// The ISO 4217 currency code
  public let currency: String
  
  /**
   Level of accuracy attached to the cost value.
   
   ### Possible values are
   - `internalEstimate`
   - `externalEstimate`
   - `confirmed`
   
   */
  public let accuracy: TKLocalCostAccuracy
  
}

extension TKLocalCost {
  
  /// Creating a new instance from a JSON object.
  ///
  /// - Parameter json: JSON object, typically obtained from server response
  /// - Returns: A new `TKLocalCost` instance.
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
