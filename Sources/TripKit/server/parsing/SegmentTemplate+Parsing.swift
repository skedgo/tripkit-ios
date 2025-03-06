//
//  SegmentTemplate+Parsing.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

#if canImport(CoreData)

import Foundation
import CoreData

extension SegmentTemplate {
  
  @discardableResult
  static func insertNewTemplate(
    from model: TKAPI.SegmentTemplate,
    for service: Service?,
    relativeTime: Date?,
    into context: NSManagedObjectContext
  ) -> SegmentTemplate? {
    
    // Only show relevant segments
    let visibility = model.visibility
    guard visibility != .hidden else { return nil }
     
    let segmentType = model.type
    
    let template = SegmentTemplate(context: context)
    
    template.action = model.action
    template.visibility = NSNumber(value: visibility.tkVisibility.rawValue)
    template.segmentType = NSNumber(value: segmentType.tkType.rawValue)
    template.hashCode = NSNumber(value: model.hashCode)
    template.bearing = model.bearing.map(NSNumber.init)
    
    template.localCost        = model.localCost
    template.mapTiles         = model.mapTiles
    template.modeIdentifier   = model.modeIdentifier
    template.modeInfo         = model.modeInfo
    template.miniInstruction  = model.mini
    template.turnByTurnMode   = model.turnByTurn
    template.notifications    = model.notifications
    template.operatorInfo     = model.operatorInfo
    
    template.notesRaw         = model.notes
    template.durationWithoutTraffic = model.durationWithoutTraffic.map(NSNumber.init)
    template.metres           = model.metres.map(NSNumber.init)
    template.metresFriendly   = model.metresSafe.map(NSNumber.init)
    template.metresUnfriendly = model.metresUnsafe.map(NSNumber.init)
    template.metresDismount   = model.metresDismount.map(NSNumber.init)
    
    template.scheduledStartStopCode = model.stopCode
    template.scheduledEndStopCode = model.endStopCode

    // These are not on the template!
    service?.operatorName = model.operatorName
    service?.operatorID = model.operatorID
    
    template.isContinuation = model.isContinuation
    template.hasCarParks = model.hasCarParks
    template.hideExactTimes = model.hideExactTimes
    
    if template.isStationary {
      // stationary segments just have a single location
      template.startLocation = model.location.map { TKNamedCoordinate($0) }
      template.endLocation = model.location.map { TKNamedCoordinate($0) }
    
    } else {
      let shapes = insertNewShapes(
        from: model,
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
      
      start = start ?? model.from.map { TKNamedCoordinate($0) }
      start?.address = model.from?.address
      end = end ?? model.to.map { TKNamedCoordinate($0) }
      end?.address = model.to?.address
      template.startLocation = start
      template.endLocation = end
    }
    
    return template
  }
  
  @discardableResult
  static func insertNewShapes(
    from model: TKAPI.SegmentTemplate,
    for service: Service?,
    relativeTime: Date?,
    modeInfo: TKModeInfo?,
    context: NSManagedObjectContext
  ) -> [Shape] {
    
    
    let shapes = Shape.insertNewShapes(
      from:  model.shapes ?? model.streets ?? [], // PT uses `shapes`, non-PT uses `streets`
      for: service,
      relativeTime: relativeTime,
      modeInfo: modeInfo ?? model.modeInfo,
      context: context,
      clearRealTime: false // we get real-time data here, no need to clear status
    )
    
    shapes
      .flatMap { $0.services ?? [] }
      .forEach { service in
        service.operatorID = model.operatorID
        service.operatorName = model.operatorName
      }
    
    return shapes
  }
  
}

#endif
