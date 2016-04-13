//
//  TKQuickBookingHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

class TKQuickBookingPrice: NSObject {
  /// Price in local currency, typically not in smallest unit, but dollars
  let localCost: Float
  
  /// Price in USD dollars
  let USDCost: Float
  
  private init(localCost: Float, USDCost: Float) {
    self.localCost = localCost
    self.USDCost = USDCost
  }
}

class TKQuickBooking: NSObject {
  /// Localised identifying this booking option
  let title: String

  /// Localised description
  let subtitle: String?
  
  /// URL to book this option. If possible, this will book it without further confirmation. These URLs are meant to be used with an instance of `BPKBookingViewController`.
  let bookingURL: NSURL

  // Localised string for doing booking
  let bookingTitle: String

  /// URL to fetch updated trip that's using this booking options. Only present if there would be a change to the trip.
  let tripUpdateURL: NSURL?
  
  /// Optional URL for image identifying this booking option
  let imageURL: NSURL?
  
  /// Optional price for this option
  let price: TKQuickBookingPrice?

  /// Localised human-friendly string, e.g., "$10"
  let priceString: String?

  /// Optional ETA for this option. This is the expected waiting time.
  let ETA: NSTimeInterval?
  
  private init(title: String, subtitle: String?, bookingURL: NSURL, bookingTitle: String, tripUpdateURL: NSURL?, imageURL: NSURL?, price: TKQuickBookingPrice?, priceString: String?, ETA: NSTimeInterval?) {
    self.title = title
    self.subtitle = subtitle
    self.bookingURL = bookingURL
    self.bookingTitle = bookingTitle
    self.tripUpdateURL = tripUpdateURL
    self.imageURL = imageURL
    self.price = price
    self.priceString = priceString
    self.ETA = ETA
  }
}

class TKQuickBookingHelper: NSObject {
  /**
   Fetches the quick booking options for a particular segment, if there are any. Each booking option represents a one-click-to-buy option uses default options for various booking customisation parameters. To let the user customise these values, do not use quick bookings, but instead the `bookingInternalURL` of a segment.
   */
  class func fetchQuickBookings(forSegment segment: TKSegment, completion: [TKQuickBooking] -> Void) {
    if let stored = segment.storedQuickBookings {
      completion(stored)
      return
    }
    
    guard let bookingsURL = segment.bookingQuickInternalURL() else {
      completion([])
      return
    }
    
    SVKServer.GET(bookingsURL, paras: nil) { response, error in
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
    
    let ETA = dictionary["ETA"] as? NSTimeInterval
    
    let tripUpdateURLString = dictionary["tripUpdateURL"] as? String
    let tripUpdateURL = tripUpdateURLString != nil ? NSURL(string: tripUpdateURLString!) : nil
    
    self.init(title: title, subtitle: subtitle, bookingURL: bookingURL, bookingTitle: bookingTitle, tripUpdateURL: tripUpdateURL, imageURL: imageURL, price: price, priceString: priceString, ETA: ETA)
  }
}

extension TKSegment {
  var storedQuickBookings: [TKQuickBooking]? {
    get {
      if let key = cacheKey(),
         let cached = TKTripKit.sharedInstance().inMemoryCache().objectForKey(key) as? [[NSString: AnyObject]] {
        return cached.flatMap { TKQuickBooking(withDictionary: $0) }
      } else {
        return nil
      }
    }
  }
  
  var activeIndexQuickBooking: Int? {
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
}
