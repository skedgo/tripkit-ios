//
//  TKPricingTable.swift
//  Pods
//
//  Created by Adrian Schoenig on 23/1/17.
//
//

import Foundation

import Marshal

/// Representation of a pricing table
///
/// Matches PricingTable from the tripgo-api
public struct TKPricingTable : Unmarshaling, Marshaling {
  
  public let title: String
  public let subtitle: String?
  public let currency: String
  public let currencySymbol: String
  public let entries: [Entry]
  
  
  /// A single entry in a pricing table
  public struct Entry: Unmarshaling, Marshaling {
    public let label: String
    public let price: Float
    
    
    public init(object: MarshaledObject) throws {
      label           = try  object.value(for: "label")
      price           = try  object.value(for: "price")
    }
    
    
    public typealias MarshalType = [String: Any]
    
    public func marshaled() -> MarshalType {
      return [
        "label": label,
        "price": price,
      ]
    }
    
  }
  

  public init(object: MarshaledObject) throws {
    title           = try  object.value(for: "title")
    entries         = try  object.value(for: "entries")
    currency        = try  object.value(for: "currency")
    currencySymbol  = try  object.value(for: "currencySymbol")
    subtitle        = try? object.value(for: "subtitle")
  }
  
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var dict: MarshalType = [
      "title": title,
      "currency": currency,
      "currencySymbol": currencySymbol,
      "entries": entries.map { $0.marshaled() },
      ]
    dict["subtitle"] = subtitle
    return dict
  }

}
