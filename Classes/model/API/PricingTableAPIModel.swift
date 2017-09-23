//
//  PricingTableAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23/1/17.
//
//

import Foundation

extension API {
  
  /// Representation of a pricing table
  ///
  /// Matches PricingTable from the tripgo-api
  public struct PricingTable : Codable {
    
    public let title: String
    public let subtitle: String?
    public let currency: String
    public let currencySymbol: String
    public let entries: [Entry]
    
    
    /// A single entry in a pricing table
    public struct Entry: Codable {
      public let label: String
      public let price: Float
    }

  }

}
