//
//  SegmentTemplate+CoreDataClass.swift
//  
//
//  Created by Adrian Schönig on 05.04.18.
//
//

import CoreData
import MapKit

/// The SegmentTemplate class keeps all the time-independent and unordered information about a segment.
///
/// It is meant to be used as a template for creating "full" Segment objects which also have  time information and a sense of ordering.
///
/// Also see `SegmentReference`. SDK users should just use `TKSegment` instead.
///
/// :nodoc:
@objc(SegmentTemplate)
public class SegmentTemplate: NSManagedObject {
}

// MARK: - Retrieving

extension SegmentTemplate {
  
  public static func segmentTemplate(withHashCode hashCode: Int, existsIn context: NSManagedObjectContext) -> Bool {
    let predicate = NSPredicate(format: "hashCode == %d", hashCode)
    return context.containsObject(SegmentTemplate.self, predicate: predicate)
  }
  
  @objc(fetchSegmentTemplateWithHashCode:inTripKitContext:)
  public static func fetchSegmentTemplate(withHashCode hashCode: Int, in context: NSManagedObjectContext) -> SegmentTemplate? {
    let predicate = NSPredicate(format: "hashCode == %d", hashCode)
    return context.fetchUniqueObject(SegmentTemplate.self, predicate: predicate)
  }
  
}

// MARK: - Computed properties

extension SegmentTemplate {
  
  @objc public var start: MKAnnotation? {
    return self.startLocation as? MKAnnotation ?? endWaypoint(atStart: true)
  }

  @objc public var end: MKAnnotation? {
    return self.endLocation as? MKAnnotation ?? endWaypoint(atStart: false)
  }

  private func endWaypoint(atStart: Bool) -> MKAnnotation? {
    // Deprecated as fallback
    guard let shape = Shape.fetchTravelledShape(for: self, atStart: atStart) else { return nil }
    return atStart ? shape.start : shape.end
  }
  
  @objc public var dashPattern: [NSNumber] {
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
  
  @objc public var isPublicTransport: Bool {
    return segmentType?.intValue == TKSegmentType.scheduled.rawValue
  }

  @objc public var isWalking: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsWalking(modeIdentifier)
  }

  @objc public var isWheelchair: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsWheelchair(modeIdentifier)
  }
  
  @objc public var isCycling: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsCycling(modeIdentifier)
  }
  
  @objc public var isDriving: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsDriving(modeIdentifier)
  }
  
  @objc public var isStationary: Bool {
    return segmentType?.intValue == TKSegmentType.stationary.rawValue
  }
  
  @objc public var isSelfNavigating: Bool {
    return turnByTurnMode != nil
  }
  
  @objc public var isAffectedByTraffic: Bool {
    return !isStationary && TKTransportModes.modeIdentifierIsAffected(byTraffic: modeIdentifier)
  }
  
  @objc public var isSharedVehicle: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsSharedVehicle(modeIdentifier)
  }
  
  @objc public var isFlight: Bool {
    guard let modeIdentifier = self.modeIdentifier else { return false }
    return TKTransportModes.modeIdentifierIsFlight(modeIdentifier)
  }
  
}

// MARK: - Computed properties (from flags)

extension SegmentTemplate {
  
  private struct FlagOptions: OptionSet {
    let rawValue: Int64
    
    static let isContinuation   = FlagOptions(rawValue: 1 << 0)
    static let hasCarParks    = FlagOptions(rawValue: 1 << 1)
  }
  
  @objc public var hasCarParks: Bool {
    get { return has(.hasCarParks) }
    set { set(.hasCarParks, to: newValue) }
  }
  
  @objc public var isContinuation: Bool {
    get { return has(.isContinuation) }
    set { set(.isContinuation, to: newValue) }
  }
  
  private func set(_ option: FlagOptions, to value: Bool) {
    var flags = FlagOptions(rawValue: self.flags?.int64Value ?? 0)
    if value {
      flags.insert(option)
    } else {
      flags.remove(option)
    }
    self.flags = NSNumber(value: flags.rawValue)
  }
  
  private func has(_ option: FlagOptions) -> Bool {
    let flags = FlagOptions(rawValue: self.flags?.int64Value ?? 0)
    return flags.contains(option)
  }
}
