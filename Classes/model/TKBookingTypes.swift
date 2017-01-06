//
//  TKBookingTypes.swift
//  Pods
//
//  Created by Adrian Schoenig on 14/12/16.
//
//

import Foundation

import Marshal
import SGCoreKit

/// Case-less enum just to create a namespace
public enum TKBooking {
  
  public struct Detail : Unmarshaling {
    public let title: String
    public let subtitle: String?
    public let imageURL: URL?
    
    public init(object: MarshaledObject) throws {
      title     = try  object.value(for: "title")
      subtitle  = try? object.value(for: "subtitle")
      imageURL  = try? object.value(for: "imageURL")
    }
  }
  

  public struct Action : Unmarshaling {
    public let title: String
    public let isDestructive: Bool
    public let internalURL: URL?
    public let externalAction: String?
    
    public init(object: MarshaledObject) throws {
      title           = try  object.value(for: "title")
      isDestructive   = try  object.value(for: "isDestructive")
      internalURL     = try? object.value(for: "internalURL")
      externalAction  = try? object.value(for: "externalURL")
    }
  }
  

  public struct TSPBranding: Unmarshaling {
    public let color: SGKColor?
    public let logoImageName: String?
    
    public init(object: MarshaledObject) throws {
      color         = try? object.value(for: "color")
      logoImageName = try? object.value(for: "imageURL")
    }
    
    public var downloadableLogoURL: URL? {
      guard let fileNamePart = logoImageName else {
        return nil
      }
      
      return SVKServer.imageURL(forIconFileNamePart: fileNamePart, of: .listMainMode)
    }
  }
  
  
  public struct Purchase : Unmarshaling {
    public let id:          String
    public let price:       NSDecimalNumber
    public let currency:    String
    public let productName: String
    public let productType: String
    public let validFor:    TimeInterval?
    public let validFrom:   Date?
    public let branding:    TSPBranding?
    
    public init(object: MarshaledObject) throws {
      id              = try  object.value(for: "id")
      let raw: Double = try object.value(for: "price")
      price = NSDecimalNumber(value: raw)
      currency        = try  object.value(for: "currency")
      productName     = try  object.value(for: "productName")
      productType     = try  object.value(for: "productType")
      validFor        = try? object.value(for: "validFor")
      validFrom       = try? object.value(for: "validFrom")
      branding        = try? object.value(for: "brand")
    }
    
    public var validTo: Date? {
      guard let from = validFrom, let duration = validFor else { return nil }
      return from.addingTimeInterval(duration)
    }
    
  }

  
  public struct Confirmation : Unmarshaling {
    
    public let status: Detail
    public let provider: Detail?
    public let vehicle: Detail?
    public let purchase: Purchase?
    public let actions: [Action]
    
    public init(object: MarshaledObject) throws {
      status    =  try  object.value(for: "status")
      provider  =  try? object.value(for: "provider")
      vehicle   =  try? object.value(for: "vehicle")
      purchase  =  try? object.value(for: "purchase")
      actions   = (try? object.value(for: "actions")) ?? []
    }
  }
  
}


