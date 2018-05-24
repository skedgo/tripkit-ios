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
/// Also see `SegmentReference`.
@objc(SegmentTemplate)
public class SegmentTemplate: NSManagedObject {

}

// MARK: - Retrieving

extension SegmentTemplate {
  
  @objc(segmentTemplateHashCode:existsInTripKitContext:)
  public static func segmentTemplate(withHashCode hashCode: Int, existsIn context: NSManagedObjectContext) -> Bool {
    let predicate = NSPredicate(format: "hashCode == %d AND toDelete = NO", hashCode)
    return context.containsObject(SegmentTemplate.self, predicate: predicate)
  }
  
  @objc(fetchSegmentTemplateWithHashCode:inTripKitContext:)
  public static func fetchSegmentTemplate(withHashCode hashCode: Int, in context: NSManagedObjectContext) -> SegmentTemplate? {
    let predicate = NSPredicate(format: "hashCode == %d AND toDelete = NO", hashCode)
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
    
    let group: SVKParserHelperMode
    if isWalking {
      group = .walking
    } else if !isPublicTransport && !isStationary {
      group = .transit
    } else {
      group = .vehicle
    }
    return SVKParserHelper.dashPattern(for: group)
  }
  
  @objc public var isPublicTransport: Bool {
    return segmentType?.intValue == TKSegmentType.scheduled.rawValue
  }

  @objc public var isWalking: Bool {
    return SVKTransportModes.modeIdentifierIsWalking(modeIdentifier)
  }

  @objc public var isWheelchair: Bool {
    return SVKTransportModes.modeIdentifierIsWheelchair(modeIdentifier)
  }
  
  @objc public var isCycling: Bool {
    return SVKTransportModes.modeIdentifierIsCycling(modeIdentifier)
  }
  
  @objc public var isDriving: Bool {
    return SVKTransportModes.modeIdentifierIsDriving(modeIdentifier)
  }
  
  @objc public var isStationary: Bool {
    return segmentType?.intValue == TKSegmentType.stationary.rawValue
  }
  
  @objc public var isSelfNavigating: Bool {
    return turnByTurnMode != nil
  }
  
  @objc public var isAffectedByTraffic: Bool {
    return !isStationary && SVKTransportModes.modeIdentifierIsAffected(byTraffic: modeIdentifier)
  }
  
  @objc public var isSharedVehicle: Bool {
    return SVKTransportModes.modeIdentifierIsSharedVehicle(modeIdentifier)
  }
  
  @objc public var isFlight: Bool {
    return SVKTransportModes.modeIdentifierIsFlight(modeIdentifier)
  }
  
}

// MARK: - Computed properties (from data)

struct SegmentTemplateData: Codable {
  var miniInstruction: STKMiniInstruction? = nil
  var modeInfo: ModeInfo? = nil
  var turnByTurnMode: TKTurnByTurnMode? = nil
  
  static func from(data: Data) -> SegmentTemplateData {
    do {
      // The new way
      return try JSONDecoder().decode(SegmentTemplateData.self, from: data)
    } catch {
      // The old way
      var templateData = SegmentTemplateData()
      if let dict = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: NSCoding] {
        templateData.modeInfo = dict["modeInfo"] as? ModeInfo
      } else {
        assertionFailure("Unexpected data: \(data). Error: \(error)")
      }
      return templateData
    }
  }
}

extension SegmentTemplate {
  
  public var miniInstruction: STKMiniInstruction? {
    get { return segmentTemplateData.miniInstruction }
    set { edit { $0.miniInstruction = newValue} }
  }
  
  @objc public var modeInfo: ModeInfo? {
    get { return segmentTemplateData.modeInfo }
    set { edit { $0.modeInfo = newValue} }
  }
  
  public var turnByTurnMode: TKTurnByTurnMode? {
    get { return segmentTemplateData.turnByTurnMode }
    set { edit { $0.turnByTurnMode = newValue} }
  }
  
  private func edit(_ mutator: (inout SegmentTemplateData) -> Void) {
    var data = segmentTemplateData
    mutator(&data)
    segmentTemplateData = data
  }
  
  private var segmentTemplateData: SegmentTemplateData {
    get {
      if let data = data as? Data {
        return SegmentTemplateData.from(data: data)
      } else {
        return SegmentTemplateData()
      }
    }
    set {
      do {
        data = try JSONEncoder().encode(newValue) as NSObject
      } catch {
        data = nil
      }
    }
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
