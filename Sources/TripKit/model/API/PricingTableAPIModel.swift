//
//  PricingTableAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23/1/17.
//
//

import Foundation

extension TKAPI {
  
  /// Representation of a pricing table
  ///
  /// Matches PricingTable from the tripgo-api
  public struct PricingTable : Codable, Hashable {
    public let title: String
    public let subtitle: String?
    public let currency: String
    public let entries: [Entry]
    
    /// A single entry in a pricing table
    public struct Entry: Codable, Hashable {
      public let label: String?
      public let price: Float
      public let maxDurationInMinutes: Int?
    }
  }

}
