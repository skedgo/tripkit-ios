//
//  SegmentReference+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation

extension SegmentReference: DataAttachable {}

struct BookingData: Codable, Hashable {
  let title: String
  
  /// Optional overwrite for `accessibilityLabel`; fallback to `title` if `nil`
  let accessibilityLabel: String?
  
  /// For in-app bookings using booking flow
  let url: URL?
  
  /// For in-app quick bookings
  let quickBookingsUrl: URL?

  /// For in-app bookings follow-up
  var confirmation: TKBooking.Confirmation?

  /// For bookings using external apps
  let externalActions: [String]?
  
  /// For virtual bookings, e.g., PT booking (GoCard) for ODIN
  let virtualBookingUrl: URL?
}

extension SegmentReference {

  var bookingData: BookingData? {
    get { decode(BookingData.self, key: "booking") }
    set { encode(newValue, key: "booking") }
  }

  var arrivalPlatform: String? {
    get { decodePrimitive(String.self, key: "arrivalPlatform") }
    set { encodePrimitive(newValue, key: "arrivalPlatform") }
  }

  var departurePlatform: String? {
    get { decodePrimitive(String.self, key: "departurePlatform") }
    set { encodePrimitive(newValue, key: "departurePlatform") }
  }
  
  var serviceStops: Int? {
    get { decodePrimitive(Int.self, key: "serviceStops") }
    set { encodePrimitive(newValue, key: "serviceStops") }
  }

  var sharedVehicle: TKAPI.SharedVehicleInfo? {
    get { decode(TKAPI.SharedVehicleInfo.self, key: "sharedVehicle") }
    set { encode(newValue, key: "sharedVehicle") }
  }

  var ticket: TKSegment.Ticket? {
    get { decode(TKSegment.Ticket.self, key: "ticket") }
    set { encode(newValue, key: "ticket") }
  }

  var ticketWebsiteURLString: String? {
    get { decodePrimitive(String.self, key: "ticketWebsiteURL") }
    set { encodePrimitive(newValue, key: "ticketWebsiteURL") }
  }

  var timetableEndTime: Date? {
    get { decodePrimitive(Date.self, key: "timetableEndTime") }
    set { encodePrimitive(newValue, key: "timetableEndTime") }
  }

  var timetableStartTime: Date? {
    get { decodePrimitive(Date.self, key: "timetableStartTime") }
    set { encodePrimitive(newValue, key: "timetableStartTime") }
  }

  @objc var vehicleUUID: String? {
    get { decodePrimitive(String.self, key: "vehicleUUID") }
    set { encodePrimitive(newValue, key: "vehicleUUID") }
  }

}

extension SegmentReference {
  func populate(from api: TKAPI.SegmentReference) {
    // Public transport
    departurePlatform = api.startPlatform
    arrivalPlatform = api.endPlatform
    serviceStops = api.serviceStops
    ticketWebsiteURLString = api.ticketWebsite?.absoluteString
    ticket = api.ticket
    timetableStartTime = api.timetableStartTime
    timetableEndTime = api.timetableEndTime
    
    // Private transport
    sharedVehicle = api.sharedVehicle
    vehicleUUID = api.vehicleUUID
    
    // Special handling to not lose booking data
    bookingHashCode = Int32(api.bookingHashCode ?? 0)
    if let booking = api.booking {
      bookingData = booking
    }
  }

}

#endif