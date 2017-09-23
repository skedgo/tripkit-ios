//
//  RegionAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 28/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension API {
  
  /// Formerly known as `TKRegionInfo`
  public struct RegionInfo: Codable {
    public let streetBicyclePaths: Bool
    public let streetWheelchairAccessibility: Bool
    public let transitModes: [API.ModeInfo]
    public let transitBicycleAccessibility: Bool
    public let transitConcessionPricing: Bool
    public let transitWheelchairAccessibility: Bool
    public let paratransit: Paratransit?
  }

  /// Informational class for paratransit information (i.e., transport for people with disabilities).
  /// Contains name of service, URL with more information and phone number.
  ///
  /// Formerly known as `TKParatransitInfo`
  /// - SeeAlso: `TKBuzzInfoProvider`'s `fetchParatransitInformation`
  public struct Paratransit: Codable {
    public let name: String
    public let url: URL
    public let number: String

    private enum CodingKeys: String, CodingKey {
      case name
      case url = "URL"
      case number
    }
  }
  
}
