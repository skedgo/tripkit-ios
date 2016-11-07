//
//  TKQuickBookingHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import Marshal

import SGCoreKit

public struct TKQuickBookingPrice {
  /// Price in local currency, typically not in smallest unit, but dollars
  public let localCost: Float
  
  /// Price in USD dollars
  public let USDCost: Float

}

public struct TKQuickBooking : Unmarshaling {
  /// Localised identifying this booking option
  public let title: String

  /// Localised description
  public let subtitle: String?
  
  /// URL to book this option. If possible, this will book it without further confirmation. These URLs are meant to be used with an instance of `BPKBookingViewController`.
  public let bookingURL: URL

  // Localised string for doing booking
  public let bookingTitle: String
  
  // URL for secondary booking flow for booking this option. This will typically let you customise the booking or pick from more options, compared to the primary `bookingURL`.
  public let secondaryBookingURL: URL?

  // Localised string for secondary booking action
  public let secondaryBookingTitle: String?

  /// URL to fetch updated trip that's using this booking options. Only present if there would be a change to the trip.
  public let tripUpdateURL: URL?
  
  /// Optional URL for image identifying this booking option
  public let imageURL: URL?
  
  /// Optional price for this option
  public let price: TKQuickBookingPrice?

  /// Localised human-friendly string, e.g., "$10"
  public let priceString: String?
  
  public let surgeString: String?
  public let surgeImageURL: URL?

  /// Optional ETA for this option. This is the expected waiting time.
  public let eta: TimeInterval?

  public init(object: MarshaledObject) throws {
    title                 = try  object.value(for: "title")
    subtitle              = try? object.value(for: "subtitle")
    imageURL              = try? object.value(for: "imageURL")
    
    bookingTitle          = try  object.value(for: "bookingTitle")
    bookingURL            = try  object.value(for: "bookingURL")
    secondaryBookingTitle = try? object.value(for: "secondaryBookingTitle")
    secondaryBookingURL   = try? object.value(for: "secondaryBookingURL")
    tripUpdateURL         = try? object.value(for: "tripUpdateURL")

    eta                   = try? object.value(for: "ETA")
    priceString           = try? object.value(for: "priceString")
    surgeString           = try? object.value(for: "surgeString")
    surgeImageURL         = try? object.value(for: "surgeImageURL")

    if let local: Float = try? object.value(for: "price"), let usd: Float = try? object.value(for: "USDPrice") {
      price = TKQuickBookingPrice(localCost: local, USDCost: usd)
    } else {
      price = nil
    }
    
  }
  
}

public struct TKBookingConfirmation : Unmarshaling {
  
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
  
  public struct Purchase : Unmarshaling {
    public let price: NSDecimalNumber
    public let currency: String
    public let productName: String
    public let productType: String
    public let id: String
    
    public init(object: MarshaledObject) throws {
      let raw: Double = try object.value(for: "price")
      price = NSDecimalNumber(value: raw)
      currency        = try  object.value(for: "currency")
      productName     = try  object.value(for: "price")
      productType     = try  object.value(for: "productType")
      id              = try  object.value(for: "id")
    }
    
  }
  
  public let status: Detail
  public let provider: Detail?
  public let vehicle: Detail?
  public let purchase: Purchase?
  public let actions: [Action]
  
  public init(object: MarshaledObject) throws {
    status    = try  object.value(for: "status")
    provider  = try? object.value(for: "provider")
    vehicle   = try? object.value(for: "vehicle")
    purchase  = try? object.value(for: "purchase")
    actions   = (try? object.value(for: "actions")) ?? []
  }
}

public enum TKQuickBookingHelper {
  /**
   Fetches the quick booking options for a particular segment, if there are any. Each booking option represents a one-click-to-buy option uses default options for various booking customisation parameters. To let the user customise these values, do not use quick bookings, but instead the `bookingInternalURL` of a segment.
   */
  public static func fetchQuickBookings(forSegment segment: TKSegment, completion: @escaping ([TKQuickBooking]) -> Void) {
    if let stored = segment.storedQuickBookings {
      completion(stored)
      return
    }
    
    guard let bookingsURL = segment.bookingQuickInternalURL() else {
      completion([])
      return
    }
    
    SVKServer.get(bookingsURL, paras: nil) { _, response, error in
      guard let array = response as? [[String: Any]], !array.isEmpty else {
        completion([])
        SGKLog.warn("TKQuickBookingHelper", text: "Response isn't array.\nResponse: \(response)\nError: \(error)")
        return
      }
      
      segment.storeQuickBookings(fromArray: array)
      let bookings = array.flatMap { try? TKQuickBooking(object: $0) }
      completion(bookings)
    }
  }

}


extension TKBookingConfirmation {
  fileprivate static func fakeTNC() -> TKBookingConfirmation? {
    let fake = [
      "actions": [
        [
          "externalURL": "tel:(555)555-5555",
          "isDestructive": false,
          "title": "Call driver"
        ],
        [
          "internalURL": "http://deep-thought:8080/satapp-debug/booking/v1/1204f411-eacb-406c-8fd2-3775c8242b02/cancel?bsb=1",
          "isDestructive": true,
          "title": "Cancel ride"
        ]
      ],
      "provider": [
        "imageURL": "https://d1a3f4spazzrp4.cloudfront.net/uberex-sandbox/images/driver.jpg",
        "subtitle": "4.9",
        "title": "John"
      ],
      "status": [
        "title": "Approaching",
        "subtitle": "Your driver is approaching"
      ],
      "vehicle": [
        "imageURL": "https://d1a3f4spazzrp4.cloudfront.net/uberex-sandbox/images/prius.jpg",
        "subtitle": "UBER-PLATE",
        "title": "Prius Toyota"
      ],
      "purchase": [
        "price": 15.80,
        "currency": "AUD",
        "productName": "uberX",
        "productType": "ps_tnc",
        "id": "1204f411-eacb-406c-8fd2-3775c8242b02",
      ]
    ] as [String : Any]
    return try? TKBookingConfirmation(object: fake)
  }

  fileprivate static func fakePublic() -> TKBookingConfirmation? {
    let fake = [
      "actions": [
        [
          "externalURL": "qrcode:http://www.skedgo.com",
          "isDestructive": false,
          "title": "View ticket"
        ],
      ],
      "status": [
        "title": "30 Minute Ticket",
        "subtitle": "Valid until 15:30",
      ],
    ] as [String : Any]
    return try? TKBookingConfirmation(object: fake)
  }
}

extension TKSegment {
  public var storedQuickBookings: [TKQuickBooking]? {
    get {
      if let key = cacheKey(),
         let cached = TKTripKit.sharedInstance().inMemoryCache().object(forKey: key as AnyObject) as? [[NSString: Any]] {
        return cached.flatMap { try? TKQuickBooking(object: $0) }
      } else {
        return nil
      }
    }
  }
  
  public var activeIndexQuickBooking: Int? {
    get {
      if let key = indexKey(),
         let index = TKTripKit.sharedInstance().inMemoryCache().object(forKey: key as AnyObject) as? Int,
         let bookings = storedQuickBookings,
         index < bookings.count {
        return index
      } else {
        return nil
      }
    }
    set {
      guard let key = indexKey(),
            let index = newValue else { return }
      
      TKTripKit.sharedInstance().inMemoryCache().setObject(index as AnyObject, forKey: key as AnyObject)
    }
  }

  fileprivate func indexKey() -> String? {
    if let path = bookingQuickInternalURL()?.path {
      return "\(path)-index"
    } else {
      return nil
    }
  }

  fileprivate func cacheKey() -> String? {
    if let path = bookingQuickInternalURL()?.path {
      return "\(path)-cached"
    } else {
      return nil
    }
  }
  
  public func storeQuickBookings(fromArray array: [[String: Any]]) {
    guard let key = cacheKey() else { return }
    
    TKTripKit.sharedInstance().inMemoryCache().setObject(array as AnyObject, forKey: key as AnyObject)
  }
  
  public var bookingConfirmation: TKBookingConfirmation? {
    if let dictionary = bookingConfirmationDictionary() {
      return try? TKBookingConfirmation(object: dictionary)
      
      // Useful for debugging the confirmation screen
//    } else if let mode = modeIdentifier() where !isStationary() && mode.hasPrefix("ps_tnc") {
//      return TKBookingConfirmation.fakeTNC()
//    } else if let mode = modeIdentifier() where !isStationary() && mode.hasPrefix("pt_pub") {
//      return TKBookingConfirmation.fakePublic()

    } else {
      return nil
    }
  }
}
