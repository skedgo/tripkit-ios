//
//  SegmentTemplate+Parsing.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension SegmentTemplate {
  
  @objc(insertNewTemplateFromDictionary:forService:relativeTime:intoContext:)
  @discardableResult
  public static func insertNewTemplate(
    from dict: [String: Any],
    for service: Service?,
    relativeTime: Date?,
    into context: NSManagedObjectContext
  ) -> SegmentTemplate? {
    
    // Only show relevant segments
    let visibility = segmentVisibilityType(from: dict)
    guard visibility != .hidden else { return nil }
     
    // Make sure we got good data
    guard
      let segmentType = segmentType(from: dict)
      else {
        assertionFailure("Segment dictionary is missing critical information")
        return nil
      }
    
    let template = SegmentTemplate(context: context)
    
    template.action = dict["action"] as? String
    template.visibility = NSNumber(value: visibility.rawValue)
    template.segmentType = NSNumber(value: segmentType.rawValue)
    template.hashCode = dict["hashCode"] as? NSNumber
    template.bearing = dict["travelDirection"] as? NSNumber
    
    template.localCost        = TKLocalCost.newInstance(from: dict["localCost"] as? [String: Any])
    template.mapTiles         = TKMapTiles.newInstance(from: dict["mapTiles"] as? [String: Any])
    template.modeIdentifier   = dict["modeIdentifier"] as? String
    template.modeInfo         = TKModeInfo.modeInfo(for: dict["modeInfo"] as? [String: Any])
    template.miniInstruction  = TKMiniInstruction.instruction(for: dict["mini"] as? [String: Any])
    template.turnByTurnMode   = TKTurnByTurnMode(rawValue: dict["turn-by-turn"] as? String ?? "")
    
    template.notesRaw         = dict["notes"] as? String
    template.smsMessage       = dict["smsMessage"] as? String
    template.smsNumber        = dict["smsNumber"] as? String
    template.durationWithoutTraffic = dict["durationWithoutTraffic"] as? NSNumber
    template.metres           = dict["metres"] as? NSNumber
    template.metresFriendly   = dict["metresSafe"] as? NSNumber
    template.metresUnfriendly = dict["metresUnsafe"] as? NSNumber
    template.metresDismount   = dict["metresDismount"] as? NSNumber
    
    if (segmentType == .scheduled) {
      template.scheduledStartStopCode = dict["stopCode"] as? String
      template.scheduledEndStopCode   = dict["endStopCode"] as? String
      
      service?.operatorName = dict["operator"] as? String
      service?.operatorID = dict["operatorID"] as? String
    }
    
    // additional info
    template.isContinuation   = dict["isContinuation"] as? Bool ?? false
    template.hasCarParks    = dict["hasCarParks"] as? Bool ?? false
    
    if template.isStationary {
      // stationary segments just have a single location
      let locationDict = (dict["location"] as? [String: Any]) ?? [:]
      let location = TKParserHelper.namedCoordinate(for: locationDict)
      template.startLocation = location
      template.endLocation = location
    
    } else {
      let shapes = insertNewShapes(
        from: dict,
        for: service, relativeTime: relativeTime,
        modeInfo: template.modeInfo, context: context
      )
      
      var start: TKNamedCoordinate? = nil
      var end: TKNamedCoordinate? = nil
      
      for shape in shapes {
        shape.template = template
        if shape.travelled {
          // Only if no previous travelled segment!
          if start == nil, let coordinate = shape.start?.coordinate {
            start = TKNamedCoordinate(coordinate: coordinate)
          }

          // ALSO if there's aprevious travelled segment
          if let coordinate = shape.end?.coordinate {
            end = TKNamedCoordinate(coordinate: coordinate)
          }
        }
      }
      
      let startDict = dict["from"] as? [String: Any]
      let endDict = dict["to"] as? [String: Any]
      if start == nil, let locationDict = startDict  {
        start = TKParserHelper.namedCoordinate(for: locationDict)
        assert(start != nil, "Got no start waypoint")
      }
      if end == nil, let locationDict = endDict {
        end = TKParserHelper.namedCoordinate(for: locationDict)
        assert(end != nil, "Got no start waypoint")
      }
      
      start?.address = startDict?["address"] as? String
      template.startLocation = start

      end?.address = endDict?["address"] as? String
      template.endLocation = end
    }
    
    return template
  }
  
  @objc(insertNewShapesFromDictionary:forService:relativeTime:modeInfo:intoContext:)
  @discardableResult
  public static func insertNewShapes(
    from dict: [String: Any],
    for service: Service?,
    relativeTime: Date?,
    modeInfo: TKModeInfo?,
    context: NSManagedObjectContext?
  ) -> [Shape] {
    
    // all the waypoints should be in 'shapes', but we
    // also support older 'streets' and 'line', e.g.,
    // for testing
    let shapesArray = (dict["shapes"] as? [[String: Any]])
      ?? (dict["streets"] as? [[String: Any]])
      ?? (dict["line"] as? [[String: Any]])
      ?? []
    
    let modeInfo = modeInfo ?? TKModeInfo.modeInfo(for: dict["modeInfo"] as? [String: Any])
    
    let shapes = TKCoreDataParserHelper.insertNewShapes(
      shapesArray, for: service, relativeTime: relativeTime,
      with: modeInfo, orTripKitContext: context,
      clearRealTime: false // we get real-time data here, no need to clear status
    )
    
    shapes
      .flatMap { $0.services ?? [] }
      .forEach { service in
        service.operatorID = dict["operatorID"] as? String
        service.operatorName = dict["operator"] as? String
      }
    
    return shapes
  }
  
  private static func segmentVisibilityType(from dict: [String: Any]) -> TKTripSegmentVisibility {
    switch dict["visibility"] as? String {
    case "in summary"?: return .inSummary
    case "on map"?: return .onMap
    case "in details"?: return .inDetails
    default: return .hidden
    }
  }
  
  private static func segmentType(from dict: [String: Any]) -> TKSegmentType? {
    switch dict["type"] as? String {
    case "scheduled"?: return .scheduled
    case "unscheduled"?: return .unscheduled
    case "stationary"?: return .stationary
    default:
      assertionFailure("Encountered unknown segment type: \(String(describing: dict["type"]))")
      return nil
    }
  }
  
}
