//
//  TKQuickBookingHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 21/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct TKQuickBookingPrice: Hashable {
  /// Price in local currency, typically not in smallest unit, but dollars
  public let localCost: Float
  
  /// Price in USD dollars
  public let USDCost: Float
}

public struct TKQuickBooking: Codable, Hashable {
  /// Localised identifying this booking option
  public let title: String

  /// Localised description
  public let subtitle: String?
  
  /// URL to book this option. If possible, this will book it without further confirmation. These URLs are meant to be used with an instance of `BPKBookingViewController`, unless `bookingURLIsDeepLink` returns `true`.
  public let bookingURL: URL

  /// Localised string for doing booking
  public let bookingTitle: String
  
  /// Whether `bookingURL` is a deep-link into an external system
  public let bookingURLIsDeepLink: Bool
  
  /// URL for secondary booking flow for booking this option. This will typically let you customise the booking or pick from more options, compared to the primary `bookingURL`.
  public let secondaryBookingURL: URL?

  /// Localised string for secondary booking action
  public let secondaryBookingTitle: String?

  /// URL to fetch updated trip that's using this booking options. Only present if there would be a change to the trip.
  public let tripUpdateURL: URL?
  
  /// Optional URL for image identifying this booking option
  public let imageURL: URL?
  
  /// Optional price for this option
  private let localPrice: Float?
  private let usdPrice: Float?
  public var price: TKQuickBookingPrice? {
    if let local = localPrice, let usd = usdPrice {
      return TKQuickBookingPrice(localCost: local, USDCost: usd)
    } else {
      return nil
    }
  }

  /// Localised human-friendly string, e.g., "$10"
  public let priceString: String?
  
  public let surgeString: String?
  public let surgeImageURL: URL?

  /// Optional ETA for this option. This is the expected waiting time.
  public let eta: TimeInterval?
  
  private enum CodingKeys: String, CodingKey {
    case title
    case subtitle
    case imageURL
    case bookingTitle
    case bookingURL
    case bookingURLIsDeepLink
    case secondaryBookingTitle
    case secondaryBookingURL
    case tripUpdateURL
    case eta = "ETA"
    case priceString
    case localPrice = "price"
    case usdPrice = "USDPrice"
    case surgeString
    case surgeImageURL
  }
  
}

public enum TKQuickBookingHelper {
  /**
   Fetches the quick booking options for a particular segment, if there are any. Each booking option represents a one-click-to-buy option uses default options for various booking customisation parameters. To let the user customise these values, do not use quick bookings, but instead the `bookingInternalURL` of a segment.
   */
  public static func fetchQuickBookings(for segment: TKSegment, completion: @escaping ([TKQuickBooking]?, Error?) -> Void) {
    if let stored = segment.storedQuickBookings {
      completion(stored, nil)
      return
    }
    
    guard let bookingsURL = segment.bookingQuickInternalURL() else {
      completion([], nil)
      return
    }
    
    TKServer.get(bookingsURL, paras: nil) { _, _, response, _, error in
      guard let array = response as? [[String: Any]], !array.isEmpty else {
        let error = error ?? NSError(code: 67123, message: "Expected an array, but got: \(String(describing: response))")
        TKLog.warn("TKQuickBookingHelper", text: "Invalid server response: \(error)")
        completion(nil, error)
        return
      }
      
      segment.storeQuickBookings(fromArray: array)
      do {
        let bookings = try JSONDecoder().decode([TKQuickBooking].self, withJSONObject: array)
        completion(bookings, nil)
      } catch {
        TKLog.warn("TKQuickBookingHelper", text: "Could not parse quick bookings due to \(error)")
        completion(nil, error)
      }
    }
  }

}


extension TKSegment {
  public var storedQuickBookings: [TKQuickBooking]? {
    get {
      if let key = cacheKey(),
         let cached = TripKit.shared.inMemoryCache().object(forKey: key as AnyObject) {
        return try? JSONDecoder().decode([TKQuickBooking].self, withJSONObject: cached)
      } else {
        return nil
      }
    }
  }
  
  public var activeIndexQuickBooking: Int? {
    get {
      if let key = indexKey(),
         let index = TripKit.shared.inMemoryCache().object(forKey: key as AnyObject) as? Int,
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
      
      TripKit.shared.inMemoryCache().setObject(index as AnyObject, forKey: key as AnyObject)
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
    
    TripKit.shared.inMemoryCache().setObject(array as AnyObject, forKey: key as AnyObject)
  }
  
  public var bookingConfirmation: TKBooking.Confirmation? {
    if let dictionary = bookingConfirmationDictionary() {
      let key: NSString?
      if let statusDict = dictionary["status"] as? [String: Any], let statusValue = statusDict["value"] as? String {
        key = (String(templateHashCode) + "-" + statusValue) as NSString
      } else {
        key = nil
      }
      if let key = key, let cached = TripKit.shared.inMemoryCache().object(forKey: key) as? TKBooking.Confirmation {
        return cached
      } else {
        do {
          let decoded = try JSONDecoder().decode(TKBooking.Confirmation.self, withJSONObject: dictionary)
          if let key = key {
            TripKit.shared.inMemoryCache().setObject(decoded as AnyObject, forKey: key)
          }
          return decoded
        } catch {
          return nil
        }
      }
    } else {
      return nil
    }
  }
}
