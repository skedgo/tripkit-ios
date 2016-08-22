//
//  TKQuickBookingHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import SGCoreKit

// Swift-only this would be a struct
public class TKQuickBookingPrice: NSObject {
  /// Price in local currency, typically not in smallest unit, but dollars
  public let localCost: Float
  
  /// Price in USD dollars
  public let USDCost: Float
  
  private init(localCost: Float, USDCost: Float) {
    self.localCost = localCost
    self.USDCost = USDCost
  }
}

// Swift-only this would be a struct
public class TKQuickBooking: NSObject {
  /// Localised identifying this booking option
  public let title: String

  /// Localised description
  public let subtitle: String?
  
  /// URL to book this option. If possible, this will book it without further confirmation. These URLs are meant to be used with an instance of `BPKBookingViewController`.
  public let bookingURL: NSURL

  // Localised string for doing booking
  public let bookingTitle: String
  
  // URL for secondary booking flow for booking this option. This will typically let you customise the booking or pick from more options, compared to the primary `bookingURL`.
  public let secondaryBookingURL: NSURL?

  // Localised string for secondary booking action
  public let secondaryBookingTitle: String?

  /// URL to fetch updated trip that's using this booking options. Only present if there would be a change to the trip.
  public let tripUpdateURL: NSURL?
  
  /// Optional URL for image identifying this booking option
  public let imageURL: NSURL?
  
  /// Optional price for this option
  public let price: TKQuickBookingPrice?

  /// Localised human-friendly string, e.g., "$10"
  public let priceString: String?
  
  public let surgeString: String?
  public let surgeImageURL: NSURL?

  /// Optional ETA for this option. This is the expected waiting time.
  public let ETA: NSTimeInterval?
  
  /// Expected waiting time. Negative if unknown. (For Obj-c compatibility.)
  public let ETARaw: NSTimeInterval
  
  private init(title: String, subtitle: String?, bookingURL: NSURL, bookingTitle: String, secondaryBookingURL: NSURL?, secondaryBookingTitle: String?, tripUpdateURL: NSURL?, imageURL: NSURL?, price: TKQuickBookingPrice?, priceString: String?, surgeText: String?, surgeImageURL: NSURL?, ETA: NSTimeInterval?) {
    self.title = title
    self.subtitle = subtitle
    self.bookingURL = bookingURL
    self.bookingTitle = bookingTitle
    self.secondaryBookingURL = secondaryBookingURL
    self.secondaryBookingTitle = secondaryBookingTitle
    self.tripUpdateURL = tripUpdateURL
    self.imageURL = imageURL
    self.price = price
    self.priceString = priceString
    self.surgeString = surgeText
    self.surgeImageURL = surgeImageURL
    self.ETA = ETA
    if let ETA = ETA {
      self.ETARaw = ETA
    } else {
      self.ETARaw = -1
    }
  }
}

// Swift-only this would be a struct
public struct TKBookingConfirmation {
  public struct Detail {
    public let title: String
    public let subtitle: String?
    public let imageURL: NSURL?
  }
  
  public struct Action {
    public let title: String
    public let isDestructive: Bool
    public let internalURL: NSURL?
    public let externalAction: NSString?
  }
  
  public struct Purchase {
    public let price: NSDecimalNumber
    public let currency: String
    public let productName: String
    public let productType: String
    public let id: String
  }
  
  public let status: Detail
  public let provider: Detail?
  public let vehicle: Detail?
  public let purchase: Purchase?
  public let actions: [Action]
}

// Swift-only this would be an enum
public class TKQuickBookingHelper: NSObject {
  /**
   Fetches the quick booking options for a particular segment, if there are any. Each booking option represents a one-click-to-buy option uses default options for various booking customisation parameters. To let the user customise these values, do not use quick bookings, but instead the `bookingInternalURL` of a segment.
   */
  public class func fetchQuickBookings(forSegment segment: TKSegment, completion: [TKQuickBooking] -> Void) {
    if let stored = segment.storedQuickBookings {
      completion(stored)
      return
    }
    
    guard let bookingsURL = segment.bookingQuickInternalURL() else {
      completion([])
      return
    }
    
    SVKServer.GET(bookingsURL, paras: nil) { _, response, error in
      guard let array = response as? [[NSString: AnyObject]] where !array.isEmpty else {
        completion([])
        SGKLog.warn("TKQuickBookingHelper", text: "Response isn't array.\nResponse: \(response)\nError: \(error)")
        return
      }
      
      segment.storeQuickBookings(fromArray: array)
      let bookings = array.flatMap { TKQuickBooking(withDictionary: $0) }
      completion(bookings)
    }
  }
  
  private override init() {
    fatalError("Don't instantiate me.")
  }
}

extension TKQuickBooking {
  private convenience init?(withDictionary dictionary: [NSString: AnyObject]) {
    guard let bookingURLString = dictionary["bookingURL"] as? String,
          let bookingURL = NSURL(string: bookingURLString),
          let bookingTitle = dictionary["bookingTitle"] as? String,
          let title = dictionary["title"] as? String
      else {
        return nil
    }
    
    let subtitle = dictionary["subtitle"] as? String
    let imageURL: NSURL?
    if let URLString = dictionary["imageURL"] as? String, URL = NSURL(string: URLString) {
      imageURL = URL
    } else {
      imageURL = nil
    }
    
    let priceString = dictionary["priceString"] as? String
    let price: TKQuickBookingPrice?
    if let local = dictionary["price"] as? Float,
       let USD = dictionary["USDPrice"] as? Float {
        price = TKQuickBookingPrice(localCost: local, USDCost: USD)
    } else {
      price = nil
    }

    let secondaryBookingTitle = dictionary["secondaryBookingTitle"] as? String
    let secondaryBookingURLString = dictionary["secondaryBookingURL"] as? String
    let secondaryBookingURL = secondaryBookingURLString != nil ? NSURL(string: secondaryBookingURLString!) : nil

    let surgeText = dictionary["surgeString"] as? String
    let surgeImageURLString = dictionary["surgeImageURL"] as? String
    let surgeImageURL = surgeImageURLString != nil ? NSURL(string: surgeImageURLString!) : nil
    
    let ETA = dictionary["ETA"] as? NSTimeInterval
    
    let tripUpdateURLString = dictionary["tripUpdateURL"] as? String
    let tripUpdateURL = tripUpdateURLString != nil ? NSURL(string: tripUpdateURLString!) : nil
    
    self.init(title: title, subtitle: subtitle,
              bookingURL: bookingURL, bookingTitle: bookingTitle,
              secondaryBookingURL: secondaryBookingURL, secondaryBookingTitle: secondaryBookingTitle,
              tripUpdateURL: tripUpdateURL,
              imageURL: imageURL,
              price: price, priceString: priceString,
              surgeText: surgeText, surgeImageURL: surgeImageURL,
              ETA: ETA
    )
  }
}

extension TKBookingConfirmation {
  private init?(withDictionary dictionary: [String: AnyObject]) {
    guard let status = Detail(withDictionary: dictionary["status"] as? [String: AnyObject]) else {
        return nil
    }
    
    let provider = Detail(withDictionary: dictionary["provider"] as? [String: AnyObject])
    let vehicle = Detail(withDictionary: dictionary["vehicle"] as? [String: AnyObject])
    let purchase = Purchase(withDictionary: dictionary["purchase"] as? [String: AnyObject])
    
    let actions: [Action]
    if let rawActions = dictionary["actions"] as? [[String: AnyObject]] {
      actions = rawActions.flatMap { Action(withDictionary: $0) }
    } else {
      actions = []
    }

    self.init(status: status, provider: provider, vehicle: vehicle, purchase: purchase, actions: actions)
  }
}

extension TKBookingConfirmation.Detail {
  private init?(withDictionary dictionary: [String: AnyObject]?) {
    guard let dictionary = dictionary,
          let title = dictionary["title"] as? String else { return nil }
    
    self.title = title
    self.subtitle = dictionary["subtitle"] as? String
    if let imageURLString = dictionary["imageURL"] as? String,
       let imageURL = NSURL(string: imageURLString) {
      self.imageURL = imageURL
    } else {
      self.imageURL = nil
    }
  }
}

extension TKBookingConfirmation.Action {
  private init?(withDictionary dictionary: [String: AnyObject]?) {
    guard let dictionary = dictionary,
      let title = dictionary["title"] as? String,
      let isDestructive = dictionary["isDestructive"] as? Bool else { return nil }
    
    self.title = title
    self.isDestructive = isDestructive
    
    if let internalURLString = dictionary["internalURL"] as? String,
      let internalURL = NSURL(string: internalURLString) {
      self.internalURL = internalURL
    } else {
      self.internalURL = nil
    }

    self.externalAction = dictionary["externalURL"] as? String
  }
}

extension TKBookingConfirmation.Purchase {
  private init?(withDictionary dictionary: [String: AnyObject]?) {
    guard
      let dictionary = dictionary,
      let price = dictionary["price"] as? Double,
      let currency = dictionary["currency"] as? String,
      let productName = dictionary["productName"] as? String,
      let productType = dictionary["productType"] as? String,
      let id = dictionary["id"] as? String
      else { return nil }
    
    self.price = NSDecimalNumber(double: price)
    self.currency = currency
    self.productName = productName
    self.productType = productType
    self.id = id
  }
}



extension TKBookingConfirmation {
  private static func fakeTNC() -> TKBookingConfirmation? {
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
    ]
    return TKBookingConfirmation(withDictionary: fake)
  }

  private static func fakePublic() -> TKBookingConfirmation? {
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
    ]
    return TKBookingConfirmation(withDictionary: fake)
  }
}

extension TKSegment {
  public var storedQuickBookings: [TKQuickBooking]? {
    get {
      if let key = cacheKey(),
         let cached = TKTripKit.sharedInstance().inMemoryCache().objectForKey(key) as? [[NSString: AnyObject]] {
        return cached.flatMap { TKQuickBooking(withDictionary: $0) }
      } else {
        return nil
      }
    }
  }
  
  public var activeIndexQuickBooking: Int? {
    get {
      if let key = indexKey(),
         let index = TKTripKit.sharedInstance().inMemoryCache().objectForKey(key) as? Int,
         let bookings = storedQuickBookings
         where index < bookings.count {
        return index
      } else {
        return nil
      }
    }
    set {
      guard let key = indexKey(),
            let index = newValue else { return }
      
      TKTripKit.sharedInstance().inMemoryCache().setObject(index, forKey: key)
    }
  }

  private func indexKey() -> String? {
    if let path = bookingQuickInternalURL()?.path {
      return "\(path)-index"
    } else {
      return nil
    }
  }

  private func cacheKey() -> String? {
    if let path = bookingQuickInternalURL()?.path {
      return "\(path)-cached"
    } else {
      return nil
    }
  }
  
  private func storeQuickBookings(fromArray array: [[NSString: AnyObject]]) {
    guard let key = cacheKey() else { return }
    
    TKTripKit.sharedInstance().inMemoryCache().setObject(array, forKey: key)
  }
  
  public var bookingConfirmation: TKBookingConfirmation? {
    if let dictionary = bookingConfirmationDictionary() {
      return TKBookingConfirmation(withDictionary: dictionary)
      
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
