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
  public enum BookingResponseKind: String, Codable, DefaultCodableStrategy {
    public static var defaultValue: TKQuickBooking.BookingResponseKind { .paymentOptions }
    
    /// Internal `BookingOptionsResponse` with providers and/or fares
    case bookingOptions = "OPTIONS"
    
    /// Internal `PaymentOptionsResponse`
    case paymentOptions = "REVIEW"
    
    /// Will confirm this option directly without further input needed
    case confirmation = "DIRECT"
    
    /// An external link, e.g., a deep link
    case external = "EXTERNAL"
  }
  
  /// Localised identifying this booking option
  public let title: String

  /// Localised description
  public let subtitle: String?
  
  public var input: [TKBooking.BookingInput]
  
  @DefaultEmptyArray public var fares: [TKBooking.Fare]
  
  @DefaultEmptyArray public var riders: [TKBooking.Rider]
  
  /// Current selected rider filter
  public var rider: TKBooking.Rider?
  
  /// URL to book this option or request more details. See `bookingURLResponse` for what kind of `URL` this is.
  public let bookingURL: URL

  /// Localised string for doing booking
  public let bookingTitle: String
  
  public var bookingResponseKind: BookingResponseKind
  
  private enum CodingKeys: String, CodingKey {
    case title
    case subtitle
    case input
    case bookingTitle
    case bookingURL
    case bookingResponseKind = "bookingResponseType"
    
    case fares
    case riders
  }
  
}

extension TKQuickBooking {
  
  /// Subset of a ``TKQuickBooking``, if it returned a subset of options to choose
  public struct AvailableOption: Codable, Hashable {
    
    /// Localised identifying this booking option
    public let title: String
    
    /// URL to book this option. If possible, this will book it without further confirmation. These URLs are meant to be used with an instance of `BPKBookingViewController`, unless `bookingURLIsDeepLink` returns `true`.
    public let bookingURL: URL
    
    @DefaultCodable<TKQuickBooking.BookingResponseKind> public var bookingResponseKind: BookingResponseKind

    /// Localised string for doing booking
    public let bookingTitle: String
    
    /// Warning to show why `bookingTitle` is disabled.
    public let warningMessage: String?
    
    @DefaultEmptyArray public var fares: [TKBooking.Fare]
    
    /// `true` if only a single fare is allowed to be selected
    @DefaultFalse public var singleFareOnly: Bool
    
    @DefaultEmptyArray public var fareGroups: [TKBooking.FareGroup]
    
    private enum CodingKeys: String, CodingKey {
      case title
      case bookingTitle
      case bookingURL
      case bookingResponseKind = "bookingResponseType"
      case warningMessage
      case fares
      case singleFareOnly
      case fareGroups
    }
  }
  
  /// Alternative to ``AvailableOption`` but not available due to `warningMessage`.
  public struct UnavailableOption: Codable, Hashable {
    /// Localised identifying this booking option
    public let title: String
    
    /// Localised string for doing booking
    public let bookingTitle: String

    /// Warning to show why `bookingTitle` is disabled.
    public let warningMessage: String
  }
  
}

public enum TKQuickBookingHelper {
  /**
   Fetches the quick booking options for a particular segment, if there are any. Each booking option represents a one-click-to-buy option uses default options for various booking customisation parameters. To let the user customise these values, do not use quick bookings, but instead the `bookingInternalURL` of a segment.
   */
  public static func fetchQuickBookings(for segment: TKSegment) async throws -> [TKQuickBooking] {
    if let stored = segment.storedQuickBookings {
      return stored
    }
    
    guard let bookingsURL = segment.bookingQuickInternalURL else {
      return []
    }
    
    let response = await TKServer.shared.hit([TKQuickBooking].self, url: bookingsURL)
    let bookings = try response.result.get()
    segment.trip.managedObjectContext?.performAndWait {
      segment.storeQuickBookings(bookings)
    }
    return bookings
  }

}


extension TKSegment {
  public var storedQuickBookings: [TKQuickBooking]? {
    get {
      if let key = cacheKey(),
         let cached = TripKit.shared.inMemoryCache.object(forKey: key as AnyObject) as? NSData {
        return try? JSONDecoder().decode([TKQuickBooking].self, from: cached as Data)
      } else {
        return nil
      }
    }
  }
  
  public var activeIndexQuickBooking: Int? {
    get {
      if let key = indexKey(),
         let index = TripKit.shared.inMemoryCache.object(forKey: key as AnyObject) as? Int,
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
      
      TripKit.shared.inMemoryCache.setObject(index as AnyObject, forKey: key as AnyObject)
    }
  }

  fileprivate func indexKey() -> String? {
    if let path = bookingQuickInternalURL?.path {
      return "\(path)-index"
    } else {
      return nil
    }
  }

  fileprivate func cacheKey() -> String? {
    if let path = bookingQuickInternalURL?.path {
      return "\(path)-cached"
    } else {
      return nil
    }
  }
  
  public func storeQuickBookings(_ bookings: [TKQuickBooking]) {
    guard let key = cacheKey() else { return }
    
    do {
      let encoded = try JSONEncoder().encode(bookings)
      TripKit.shared.inMemoryCache.setObject(encoded as NSData, forKey: key as AnyObject)
    } catch {
      TKLog.warn("Couldn't encode quick bookings: \(error)")
    }
  }
  
}
