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
    @ISO8601OrSecondsSince1970 public var depart: Date
    @ISO8601OrSecondsSince1970 public var arrive: Date
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
    public var ticketWebsite: URL?
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
    public var localCost: TKLocalCost?
    var mini: TKMiniInstruction?

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
