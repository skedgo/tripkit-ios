//
//  RoutingAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreLocation

extension TKAPI {

  public struct RoutingResponse: Codable {
    public let error: String?
    public var segmentTemplates: [SegmentTemplate]?
    @DefaultEmptyArray public var alerts: [Alert]
    public let groups: [TripGroup]?
    public let query: Query?
  }
  
  public struct Query: Codable, Hashable {
    public let from: TKNamedCoordinate
    public let to: TKNamedCoordinate
    @OptionalISO8601OrSecondsSince1970 public var depart: Date?
    @OptionalISO8601OrSecondsSince1970 public var arrive: Date?
  }
  
  public struct TripGroup: Codable, Hashable {
    public let trips: [Trip]
    public var frequency: Int?
    @DefaultEmptyArray public var sources: [DataAttribution]
  }
  
  public struct Trip: Codable, Hashable {
    public var id: String?
    @ISO8601OrSecondsSince1970 public var depart: Date
    @ISO8601OrSecondsSince1970 public var arrive: Date
    @DefaultFalse public var hideExactTimes: Bool
    public let mainSegmentHashCode: Int
    public let segments: [SegmentReference]
    
    public let caloriesCost: Double
    public let carbonCost: Double
    public let hassleCost: Double
    public let weightedScore: Double
    
    public var moneyCost: Double?
    public var moneyCostUSD: Double?
    public var currency: String?
    
    public var budgetPoints: Double?
    public var bundleId: String?
    
    public var saveURL: URL?
    public var shareURL: URL?
    public var temporaryURL: URL?
    public var updateURL: URL?
    public var progressURL: URL?
    public var plannedURL: URL?
    public var logURL: URL?
    
    @UnknownNil public var availability: TripAvailability?
  }
  
  public enum TripAvailability: String, Codable, Hashable {
    case missedPrebookingWindow = "MISSED_PREBOOKING_WINDOW"
    case canceled               = "CANCELLED"
  }

  public struct SegmentReference: Codable, Hashable {
    public let segmentTemplateHashCode: Int
    @ISO8601OrSecondsSince1970 public var startTime: Date
    @ISO8601OrSecondsSince1970 public var endTime: Date
    @DefaultFalse public var timesAreRealTime: Bool
    @DefaultEmptyArray public var alertHashCodes: [Int]
    var booking: BookingData?
    public var bookingHashCode: Int?
    
    // Public transport
    public var serviceTripID: String?
    public var serviceColor: RGBColor?
    public var frequency: Int?
    public var lineName: String?
    public var direction: String?
    public var number: String?
    @DefaultFalse public var bicycleAccessible: Bool
    public var wheelchairAccessible: Bool? // `nil` means unknown
    public var startPlatform: String?
    public var endPlatform: String?
    public var serviceStops: Int?
    @UnknownNil public var ticketWebsite: URL? // Backend might send empty string, which is not a valid URL
    public var ticket: TKSegment.Ticket?
    @OptionalISO8601OrSecondsSince1970 public var timetableStartTime: Date?
    @OptionalISO8601OrSecondsSince1970 public var timetableEndTime: Date?
    @UnknownNil public var realTimeStatus: RealTimeStatus?
    
    // PT and non-PT
    public var realTimeVehicle: Vehicle?
    @DefaultEmptyArray public var realTimeVehicleAlternatives: [Vehicle]
    @UnknownNil public var sharedVehicle: TKAPI.SharedVehicleInfo?
    public var vehicleUUID: String?

    enum CodingKeys: String, CodingKey {
      case segmentTemplateHashCode
      case startTime
      case endTime
      case timesAreRealTime = "realTime"
      case alertHashCodes
      case booking
      case bookingHashCode
      case serviceTripID
      case serviceColor
      case frequency
      case lineName = "serviceName"
      case direction = "serviceDirection"
      case number = "serviceNumber"
      case bicycleAccessible
      case wheelchairAccessible
      case startPlatform
      case endPlatform
      case serviceStops = "stops"
      case ticketWebsite = "ticketWebsiteURL"
      case ticket
      case timetableStartTime
      case timetableEndTime
      case realTimeStatus
      case realTimeVehicle = "realtimeVehicle"
      case realTimeVehicleAlternatives = "realtimeVehicleAlternatives"
      case sharedVehicle
      case vehicleUUID
    }
  }
  
  public struct SegmentTemplate: Codable, Hashable {
    public let hashCode: Int
    public let type: SegmentType
    public let visibility: SegmentVisibility
    public let modeIdentifier: String?
    public let modeInfo: TKModeInfo?

    public let action: String?
    public var notes: String?
    @UnknownNil public var localCost: TKLocalCost? // Backend is sometimes sending this invalid without currency as of 2021-08-17
    @DefaultEmptyArray public var notifications: [TripNotification]
    var mini: TKMiniInstruction?
    @DefaultFalse var hideExactTimes: Bool

    // stationary
    public var location: TKNamedCoordinate?
    @DefaultFalse public var hasCarParks: Bool

    // moving
    public var bearing: Int?
    public var from: TKNamedCoordinate?
    public var to: TKNamedCoordinate?

    // moving.unscheduled
    public var metres: CLLocationDistance?
    public var metresSafe: CLLocationDistance?
    public var metresUnsafe: CLLocationDistance?
    public var metresDismount: CLLocationDistance?
    public var durationWithoutTraffic: TimeInterval?
    public var mapTiles: TKMapTiles?
    @UnknownNil public var turnByTurn: TKTurnByTurnMode?
    public var streets: [SegmentShape]?

    // moving.scheduled
    public var stopCode: String? // scheduledStartStopCode
    public var endStopCode: String?
    public var operatorName: String?
    public var operatorID: String?
    @DefaultFalse public var isContinuation: Bool
    public var shapes: [SegmentShape]?

    enum CodingKeys: String, CodingKey {
      case hashCode
      case type
      case visibility
      case modeIdentifier
      case modeInfo
      case action
      case notes
      case metres
      case metresSafe
      case metresUnsafe
      case metresDismount
      case durationWithoutTraffic
      case bearing = "travelDirection"
      case localCost
      case mapTiles
      case mini
      case hideExactTimes
      case turnByTurn = "turn-by-turn"
      case streets
      case stopCode
      case endStopCode
      case operatorName = "operator"
      case operatorID
      case isContinuation
      case hasCarParks
      case location
      case from
      case to
      case shapes
      case notifications = "geofences"
    }
  }
  
  public enum SegmentVisibility: String, Codable, Hashable {
    case inSummary = "in summary"
    case onMap = "on map"
    case inDetails = "in details"
    case hidden
    
    var tkVisibility: TKTripSegmentVisibility {
      switch self {
      case .inSummary: return .inSummary
      case .onMap: return .onMap
      case .inDetails: return .inDetails
      case .hidden: return .hidden
      }
    }
  }
  
  public enum SegmentType: String, Codable, Hashable {
    case scheduled
    case unscheduled
    case stationary
    
    var tkType: TKSegmentType {
      switch self {
      case .stationary: return .stationary
      case .scheduled: return .scheduled
      case .unscheduled: return .unscheduled
      }
    }
  }
  
  public struct TripNotification: Hashable {
    public enum Kind: Hashable {
      case circle(center: CLLocationCoordinate2D, radius: CLLocationDistance, trigger: Trigger)
      case time(Date)

      public static func == (lhs: TKAPI.TripNotification.Kind, rhs: TKAPI.TripNotification.Kind) -> Bool {
        switch (lhs, rhs) {
        case let (.circle(lc, lr, lt), .circle(rc, rr, rt)):
          return lc.latitude == rc.latitude
              && lc.longitude == rc.longitude
              && lr == rr
              && lt == rt
        case let (.time(lhs), .time(rhs)):
          return lhs == rhs
        default:
          return false
        }
      }
      
      public func hash(into hasher: inout Hasher) {
        switch self {
        case let .circle(center, radius, trigger):
          hasher.combine(center.latitude)
          hasher.combine(center.longitude)
          hasher.combine(radius)
          hasher.combine(trigger)
        case let .time(date):
          hasher.combine(date)
        }
      }
      
    }
    
    struct Coordinate: Codable {
      let lat: CLLocationDegrees
      let lng: CLLocationDegrees
    }
    
    public enum Trigger: String, Codable, Hashable {
      case onEnter = "ENTER"
      case onExit = "EXIT"
    }
    
    public enum MessageKind: String, Codable, Hashable {
      case tripStart          = "TRIP_START"
      case tripEnd            = "TRIP_END"
      case arrivingAtYourStop = "ARRIVING_AT_YOUR_STOP"
      case nextStopIsYours    = "NEXT_STOP_IS_YOURS"
    }
    
    public let id: String
    public let kind: Kind
    public let messageKind: MessageKind
    public var messageTitle: String
    public var messageBody: String
  }
  
  public struct SegmentShape: Codable, Hashable {
    public let encodedWaypoints: String

    public var modeInfo: TKModeInfo?
    @DefaultTrue public var travelled: Bool
    
    // scheduled
    public var serviceTripID: String?
    public var serviceColor: RGBColor?
    public var frequency: Int?
    public var lineName: String?
    public var direction: String?
    public var number: String?
    @DefaultFalse public var bicycleAccessible: Bool
    public var wheelchairAccessible: Bool?
    public var operatorName: String?
    public var operatorID: String?
    public var routeID: String?
    @DefaultEmptyArray public var stops: [TKAPI.ShapeStop]
    
    // unscheduled
    public var name: String?
    @DefaultFalse public var dismount: Bool
    @DefaultFalse public var hop: Bool
    public var metres: CLLocationDistance?
    public var cyclingNetwork: String?
    public var safe: Bool?
    @UnknownNil public var instruction: ShapeInstruction?
    @EmptyLossyArray @LossyArray public var roadTags: [Shape.RoadTag]
    
    enum CodingKeys: String, CodingKey {
      case encodedWaypoints
      case modeInfo
      case travelled
      case serviceTripID
      case serviceColor
      case frequency
      case lineName = "serviceName"
      case direction = "serviceDirection"
      case number = "serviceNumber"
      case bicycleAccessible
      case wheelchairAccessible
      case operatorName = "operator"
      case operatorID
      case routeID
      case stops
      case name
      case dismount
      case hop
      case metres
      case cyclingNetwork
      case safe
      case instruction
      case roadTags
    }
  }
  
  public struct ShapeStop: Codable, Hashable {
    public let lat: CLLocationDegrees
    public let lng: CLLocationDegrees
    public let code: String
    public let name: String
    public let shortName: String?

    @OptionalISO8601OrSecondsSince1970 public var arrival: Date?
    @OptionalISO8601OrSecondsSince1970 public var departure: Date?
    public var relativeArrival: TimeInterval?
    public var relativeDeparture: TimeInterval?
    public var bearing: Int?
    public let wheelchairAccessible: Bool?
  }
  
  public enum ShapeInstruction: String, Codable {
    case headTowards        = "HEAD_TOWARDS"
    case continueStraight   = "CONTINUE_STRAIGHT"
    case turnSlightyLeft    = "TURN_SLIGHTLY_LEFT"
    case turnLeft           = "TURN_LEFT"
    case turnSharplyLeft    = "TURN_SHARPLY_LEFT"
    case turnSlightlyRight  = "TURN_SLIGHTLY_RIGHT"
    case turnRight          = "TURN_RIGHT"
    case turnSharplyRight   = "TURN_SHARPLY_RIGHT"
  }
    
}

extension TKAPI.TripNotification: Codable {
  
  public enum CodingKeys: String, CodingKey {
    case id
    case kind = "type"
    case messageKind = "messageType"
    case messageTitle
    case messageBody
    
    // geofences
    case center
    case radius
    case trigger

    // time-based
    case time
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    
    messageKind = try container.decode(MessageKind.self, forKey: .messageKind)
    messageTitle = try container.decode(String.self, forKey: .messageTitle)
    messageBody = try container.decode(String.self, forKey: .messageBody)

    let rawKind = try container.decode(String.self, forKey: .kind)
    switch rawKind {
    case "CIRCLE":
      let coordinate = try container.decode(Coordinate.self, forKey: .center)
      let radius = try container.decode(CLLocationDistance.self, forKey: .radius)
      let trigger = try container.decode(Trigger.self, forKey: .trigger)
      kind = .circle(center: .init(latitude: coordinate.lat, longitude: coordinate.lng), radius: radius, trigger: trigger)
    case "TIME":
      let date = try container.decode(ISO8601OrSecondsSince1970.self, forKey: .time)
      kind = .time(date.wrappedValue)
    default:
      throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Expected 'type' of value 'CIRCLE', but got '\(rawKind)'"))
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(messageKind, forKey: .messageKind)
    try container.encode(messageTitle, forKey: .messageTitle)
    try container.encode(messageBody, forKey: .messageBody)
    switch kind {
    case let .circle(center, radius, trigger):
      try container.encode("CIRCLE", forKey: .kind)
      try container.encode(Coordinate(lat: center.latitude, lng: center.longitude), forKey: .center)
      try container.encode(radius, forKey: .radius)
      try container.encode(trigger, forKey: .trigger)
    case let .time(date):
      try container.encode("TIME", forKey: .kind)
      try container.encode(date, forKey: .time)
    }
  }
  
}
