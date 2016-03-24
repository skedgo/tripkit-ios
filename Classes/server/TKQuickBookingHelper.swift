//
//  TKQuickBookingHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

struct TKQuickBookingPrice {
  /// Localised human-friendly string, e.g., "$10"
  let string: String
  
  /// Price in local currency, typically not in smallest unit, but dollars
  let localCost: Float
  
  /// Price in USD dollars
  let USDCost: Float
}

struct TKQuickBooking {
  /// Localised identifying this booking option
  let title: String
  
  /// URL to book this option. If possible, this will book it without further confirmation. These URLs are meant to be used with an instance of `BPKBookingViewController`.
  let bookingURL: NSURL
  
  /// Optional URL for image identifying this booking option
  let imageURL: NSURL?
  
  /// Optional price for this option
  let price: TKQuickBookingPrice?
  
  /// Optional ETA for this option. This is the expected waiting time.
  let ETA: NSTimeInterval?
}

class TKQuickBookingHelper {
  /**
   Fetches the quick booking options for a particular segment, if there are any. Each booking option represents a one-click-to-buy option uses default options for various booking customisation parameters. To let the user customise these values, do not use quick bookings, but instead the `bookingInternalURL` of a segment.
   */
  class func fetchQuickBookings(forSegment segment: TKSegment, completion: [TKQuickBooking] -> Void) {
    guard let bookingsURL = segment.bookingQuickInternalURL() else {
      completion([])
      return
    }
    
    SVKServer.GET(bookingsURL, paras: nil) { response, error in
      guard let array = response as? [[NSString: AnyObject]] where !array.isEmpty else {
        completion([])
        SGKLog.warn("TKQuickBookingHelper", text: "No reponse. Error: \(error)")
        return
      }
      
      let bookings = array.flatMap { TKQuickBooking(withDictionary: $0) }
      completion(bookings)
    }
  }
}

extension TKQuickBooking {
  private init?(withDictionary dictionary: [NSString: AnyObject]) {
    guard let bookingURLString = dictionary["bookingURL"] as? String,
          let bookingURL = NSURL(string: bookingURLString),
          let title = dictionary["title"] as? String
      else {
        return nil
    }
    
    let imageURL: NSURL?
    if let URLString = dictionary["imageURL"] as? String, URL = NSURL(string: URLString) {
      imageURL = URL
    } else {
      imageURL = nil
    }
    
    let price: TKQuickBookingPrice?
    if let string = dictionary["priceString"] as? String,
       let local = dictionary["price"] as? Float,
       let USD = dictionary["USDPrice"] as? Float {
        price = TKQuickBookingPrice(string: string, localCost: local, USDCost: USD)
    } else {
      price = nil
    }
    
    let ETA = dictionary["ETA"] as? NSTimeInterval
    
    self.init(title: title, bookingURL: bookingURL, imageURL: imageURL, price: price, ETA: ETA)
  }
}

