//
//  SegmentReference+Data.swift
//  TripKit
//
//  Created by Adrian Schönig on 14.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension SegmentReference: DataAttachable {}

public struct BookingData: Codable, Hashable {
  let title: String
  
  /// For in-app bookings using booking flow
  let url: URL?
  
  /// For in-app quick bookings
  let quickBookingsUrl: URL?

  /// For in-app bookings follow-up
  public var confirmation: TKBooking.Confirmation?

  /// For bookings using external apps
  let externalActions: [String]?
}

extension SegmentReference {

  public var bookingData: BookingData? {
    get { decode(BookingData.self, key: "booking") }
    set { encode(newValue, key: "booking") }
  }

  public var arrivalPlatform: String? {
    get { decode(String.self, key: "arrivalPlatform") }
    set { encode(newValue, key: "arrivalPlatform") }
  }

  public var departurePlatform: String? {
    get { decode(String.self, key: "departurePlatform") }
    set { encode(newValue, key: "departurePlatform") }
  }
  
  var serviceStops: Int? {
    get { decode(Int.self, key: "serviceStops") }
    set { encode(newValue, key: "serviceStops") }
  }

  public var sharedVehicleData: NSDictionary? {
    get { decodeCoding(NSDictionary.self, key: "sharedVehicle") }
    set { encodeCoding(newValue, key: "sharedVehicle") }
  }

  public var ticket: TKSegment.Ticket? {
    get { decode(TKSegment.Ticket.self, key: "ticket") }
    set { encode(newValue, key: "ticket") }
  }

  public var ticketWebsiteURLString: String? {
    get { decode(String.self, key: "ticketWebsiteURL") }
    set { encode(newValue, key: "ticketWebsiteURL") }
  }

  public var timetableEndTime: Date? {
    get { decode(Date.self, key: "timetableEndTime") }
    set { encode(newValue, key: "timetableEndTime") }
  }

  public var timetableStartTime: Date? {
    get { decode(Date.self, key: "timetableStartTime") }
    set { encode(newValue, key: "timetableStartTime") }
  }

  @objc public var vehicleUUID: String? {
    get { decode(String.self, key: "vehicleUUID") }
    set { encode(newValue, key: "vehicleUUID") }
  }
}

extension SegmentReference {
  /// :nodoc:
  @objc(_populateFromDictionary:)
  public func populate(from dict: [String: AnyHashable]) {
    // Public transport
    arrivalPlatform = dict["endPlatform"] as? String
    departurePlatform = dict["platform"] as? String
    serviceStops = (dict["stops"] as? NSNumber)?.intValue
    ticketWebsiteURLString = dict["ticketWebsiteURL"] as? String
    if let ticketDict = dict["ticket"] as? [String: AnyHashable] {
      ticket = try? JSONDecoder().decode(TKSegment.Ticket.self, withJSONObject: ticketDict)
    }
    if let start = dict["timetableStartTime"] as? TimeInterval {
      timetableStartTime = Date(timeIntervalSince1970: start)
    }
    if let end = dict["timetableEndTime"] as? TimeInterval {
      timetableEndTime = Date(timeIntervalSince1970: end)
    }
    
    // Private transport
    sharedVehicleData = dict["sharedVehicle"] as? NSDictionary
    vehicleUUID = dict["vehicleUUID"] as? String
    
    // Special booking handling to not lose data
    if let bookingDict = dict["booking"] as? [String: AnyHashable] {
      do {
        bookingData = try JSONDecoder().decode(BookingData.self, withJSONObject: bookingDict)
      } catch {
        TKLog.warn(#file, text: "Could not load booking data: \(error)")
      }
    }
    
    // What is this even used for?
    if let payloads = dict["payloads"] as? [String: NSDictionary] {
      for payload in payloads {
        encodeCoding(payload.value, key: payload.key)
      }
    }
  }

}
