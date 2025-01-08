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
  
  // - START: Temporary backwards compatibility 1/2
  // When all backends are upgraded, this can be
  // public var bookingResponseKind: BookingResponseKind
  
  public var bookingResponseKind: BookingResponseKind {
    if let provided = _bookingResponseKind {
      return provided
    } else if billingEnabled == true {
      return .paymentOptions
    } else if bookingURLIsDeepLink == true {
      return .external
    } else {
      return .confirmation
    }
  }
  
  private var _bookingResponseKind: BookingResponseKind?
  private var billingEnabled: Bool?
  private let bookingURLIsDeepLink: Bool?
  
  // - END: Temporary backwards compatibility 1/2
  
  
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
    case input
    case imageURL
    case bookingTitle
    case bookingURL
    
    // - START: Temporary backwards compatibility 2/2
    // case bookingResponseKind = "bookingResponseType"
    case _bookingResponseKind = "bookingResponseType"
    case billingEnabled
    case bookingURLIsDeepLink
    // - END: Temporary backwards compatibility 2/2
    
    case secondaryBookingTitle
    case secondaryBookingURL
    case tripUpdateURL
    case eta = "ETA"
    case priceString
    case localPrice = "price"
    case usdPrice = "USDPrice"
    case surgeString
    case surgeImageURL
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
    
    @DefaultEmptyArray public var fares: [TKBooking.Fare]
    
    /// `true` if only a single fare is allowed to be selected
    @DefaultFalse public var singleFareOnly: Bool
    
    private enum CodingKeys: String, CodingKey {
      case title
      case bookingTitle
      case bookingURL
      case bookingResponseKind = "bookingResponseType"
      case fares
      case singleFareOnly
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
