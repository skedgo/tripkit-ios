//
//  BookingData.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

import Foundation

public struct TKBookingData: Codable, Hashable, Sendable {
  public let title: String
  
  /// Optional overwrite for `accessibilityLabel`; fallback to `title` if `nil`
  public let accessibilityLabel: String?
  
  /// For in-app bookings using booking flow
  public let url: URL?
  
  /// For in-app quick bookings
  public let quickBookingsUrl: URL?

  /// For in-app bookings follow-up
  public var confirmation: TKBooking.Confirmation?

  /// For bookings using external apps
  public let externalActions: [String]?
  
  /// For virtual bookings, e.g., PT booking (GoCard) for ODIN
  public let virtualBookingUrl: URL?
}
