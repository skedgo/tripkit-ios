//
//  SegmentTemplate+CoreDataClass.swift
//  
//
//  Created by Adrian Schönig on 05.04.18.
//
//

#if canImport(CoreData)

import CoreData
import MapKit

/// The SegmentTemplate class keeps all the time-independent and unordered information about a segment.
///
/// It is meant to be used as a template for creating "full" Segment objects which also have  time information and a sense of ordering.
///
/// Also see `SegmentReference`. SDK users should just use `TKSegment` instead.
///
@objc(SegmentTemplate)
class SegmentTemplate: NSManagedObject {
}

// MARK: - Retrieving

extension SegmentTemplate {
  
  static func segmentTemplate(withHashCode hashCode: Int, existsIn context: NSManagedObjectContext) -> Bool {
    let predicate = NSPredicate(format: "hashCode == %d", hashCode)
    return context.containsObject(SegmentTemplate.self, predicate: predicate)
  }
  
  static func fetchSegmentTemplate(withHashCode hashCode: Int, in context: NSManagedObjectContext) -> SegmentTemplate? {
    let predicate = NSPredicate(format: "hashCode == %d", hashCode)
    return context.fetchUniqueObject(SegmentTemplate.self, predicate: predicate)
  }
  
}

// MARK: - Computed properties

extension SegmentTemplate {
  
  var start: MKAnnotation? {
    return self.startLocation as? MKAnnotation ?? endWaypoint(atStart: true)
  }

  var end: MKAnnotation? {
    return self.endLocation as? MKAnnotation ?? endWaypoint(atStart: false)
  }

  private func endWaypoint(atStart: Bool) -> MKAnnotation? {
    // Deprecated as fallback
    guard let shape = Shape.fetchTravelledShape(for: self, atStart: atStart) else { return nil }
    return atStart ? shape.start : shape.end
  }
  
  var dashPattern: [NSNumber] {
    if modeInfo?.color != nil {
      return [1] // no dashes if we have dedicated color
    }
    
    // walking has regular dashes; driving has longer dashes, public has full lines
    if isWalking {
      return [1, 10]
    } else if !isPublicTransport && !isStationary {
      return [10, 20]
    } else {
      return [1]
    }
  }
  
  var isPublicTransport: Bool {
    return segmentType?.intValue == TKSegmentType.scheduled.rawValue
  }

  var isWalking: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsWalking(modeIdentifier)
  }

  var isWheelchair: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsWheelchair(modeIdentifier)
  }
  
  var isCycling: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsCycling(modeIdentifier)
  }
  
  var isDriving: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsDriving(modeIdentifier)
  }
  
  var isStationary: Bool {
    return segmentType?.intValue == TKSegmentType.stationary.rawValue
  }
  
  var isSelfNavigating: Bool {
    return turnByTurnMode != nil
  }
  
  var isAffectedByTraffic: Bool {
    return !isStationary && TKTransportModes.modeIdentifierIsAffected(byTraffic: modeIdentifier)
  }
  
  var isSharedVehicle: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsSharedVehicle(modeIdentifier)
  }
  
  var isFlight: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsFlight(modeIdentifier)
  }
  
}

#endif
