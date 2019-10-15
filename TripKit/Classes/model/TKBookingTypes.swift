//
//  TKBookingTypes.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/12/16.
//
//

import Foundation

/// Case-less enum just to create a namespace
public enum TKBooking {
  
  public struct Detail: Codable, Hashable {
    public let title: String
    public let subtitle: String?
    public let imageURL: URL?
  }
  

  public struct Action: Codable, Hashable {
    public let title: String
    public let isDestructive: Bool
    public let internalURL: URL?
    public let externalAction: String?
    
    private enum CodingKeys: String, CodingKey {
      case title
      case isDestructive
      case internalURL
      case externalAction = "externalURL"
    }
  }
  

  public struct TSPBranding: Codable, Hashable {
    private let rgbColor: API.RGBColor?
    private let logoImageName: String?
    
    private enum CodingKeys: String, CodingKey {
      case rgbColor = "color"
      case logoImageName = "remoteIcon"
    }
    
    public var color: TKColor? {
      return rgbColor?.color
    }
    
    public var downloadableLogoURL: URL? {
      guard let fileNamePart = logoImageName else { return nil }
      return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: .listMainMode)
    }
  }
  
  
  public struct Purchase: Codable, Hashable {
    public let id:                  String
    private let rawPrice:           Double?
    public let currency:            String?
    public let budgetPoints:        Int?
    public let productName:         String
    public let productType:         String
    private let explicitValidity:   Bool?
    public let validFor:            TimeInterval?
    public let validFrom:           Date?
    public let branding:            TSPBranding?
    public let attribution:         API.DataAttribution?
    
    private enum CodingKeys: String, CodingKey {
      case id
      case rawPrice = "price"
      case currency
      case budgetPoints
      case productName
      case productType
      case explicitValidity = "valid"
      case validFor
      case validFrom
      case branding = "brand"
      case attribution = "source"
    }
    
    public var price: NSDecimalNumber? {
      guard let rawPrice = rawPrice else { return nil }
      return NSDecimalNumber(value: rawPrice)
    }
    
    public var isValid: Bool {
      if let valid = explicitValidity { return valid }
      
      // If we don't have an expiry date for the ticket, treat it as valid.
      guard let ticketExpiryDate = validTo else {
        assertionFailure("Purchase has neither valid nor validFrom + validFor")
        return true
      }
      
      // Expiring in the future
      return ticketExpiryDate.timeIntervalSinceNow > 0
    }
    
    public var validTo: Date? {
      guard let from = validFrom, let duration = validFor else { return nil }
      return from.addingTimeInterval(duration)
    }
    
  }

  public struct Confirmation : Codable, Hashable {
    
    public let status: Detail
    public let provider: Detail?
    public let vehicle: Detail?
    public let purchase: Purchase?
    public let actions: [Action]?
  }
  
}
