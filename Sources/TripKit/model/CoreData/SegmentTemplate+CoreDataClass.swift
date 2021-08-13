//
//  SegmentTemplate+CoreDataClass.swift
//  
//
//  Created by Adrian Schönig on 05.04.18.
//
//

import CoreData
import MapKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

/// The SegmentTemplate class keeps all the time-independent and unordered information about a segment.
///
/// It is meant to be used as a template for creating "full" Segment objects which also have  time information and a sense of ordering.
///
/// Also see `SegmentReference`. SDK users should just use `TKSegment` instead.
///
/// :nodoc:
@objc(SegmentTemplate)
class SegmentTemplate: NSManagedObject {
}

// MARK: - Retrieving

extension SegmentTemplate {
  
  static func segmentTemplate(withHashCode hashCode: Int, existsIn context: NSManagedObjectContext) -> Bool {
    let predicate = NSPredicate(format: "hashCode == %d", hashCode)
    return context.containsObject(SegmentTemplate.self, predicate: predicate)
  }
  
  @objc(fetchSegmentTemplateWithHashCode:inTripKitContext:)
  static func fetchSegmentTemplate(withHashCode hashCode: Int, in context: NSManagedObjectContext) -> SegmentTemplate? {
    let predicate = NSPredicate(format: "hashCode == %d", hashCode)
    return context.fetchUniqueObject(SegmentTemplate.self, predicate: predicate)
  }
  
}

// MARK: - Computed properties

extension SegmentTemplate {
  
  @objc var start: MKAnnotation? {
    return self.startLocation as? MKAnnotation ?? endWaypoint(atStart: true)
  }

  @objc var end: MKAnnotation? {
    return self.endLocation as? MKAnnotation ?? endWaypoint(atStart: false)
  }

  private func endWaypoint(atStart: Bool) -> MKAnnotation? {
    // Deprecated as fallback
    guard let shape = Shape.fetchTravelledShape(for: self, atStart: atStart) else { return nil }
    return atStart ? shape.start : shape.end
  }
  
  @objc var dashPattern: [NSNumber] {
    if modeInfo?.color != nil {
      return [1] // no dashes if we have dedicated color
    }
    
    let group: TKParserHelperMode
    if isWalking {
      group = .walking
    } else if !isPublicTransport && !isStationary {
      group = .transit
    } else {
      group = .vehicle
    }
    return TKParserHelper.dashPattern(for: group)
  }
  
  @objc var isPublicTransport: Bool {
    return segmentType?.intValue == TKSegmentType.scheduled.rawValue
  }

  @objc var isWalking: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsWalking(modeIdentifier)
  }

  @objc var isWheelchair: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsWheelchair(modeIdentifier)
  }
  
  @objc var isCycling: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsCycling(modeIdentifier)
  }
  
  @objc var isDriving: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsDriving(modeIdentifier)
  }
  
  @objc var isStationary: Bool {
    return segmentType?.intValue == TKSegmentType.stationary.rawValue
  }
  
  @objc var isSelfNavigating: Bool {
    return turnByTurnMode != nil
  }
  
  @objc var isAffectedByTraffic: Bool {
    return !isStationary && TKTransportModes.modeIdentifierIsAffected(byTraffic: modeIdentifier)
  }
  
  @objc var isSharedVehicle: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsSharedVehicle(modeIdentifier)
  }
  
  @objc var isFlight: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsFlight(modeIdentifier)
  }
  
}
