//
//  Service.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

// MARK: - Insertions

extension Service {
  
  @objc(fetchOrInsertServiceWithCode:inTripKitContext:)
  public static func fetchOrInsert(code: String, in context: NSManagedObjectContext) -> Service {
    if let existing = fetchExistingService(code: code, in: context) {
      return existing
    }
    
    let service = Service(context: context)
    service.code = code
    return service
  }
  
  @objc(fetchExistingServiceWithCode:inTripKitContext:)
  public static func fetchExistingService(code: String, in context: NSManagedObjectContext) -> Service? {
    
    let equalServiceCode = NSPredicate(format: "code = %@", code)
    let match = context.fetchUniqueObject(Service.self, predicate: equalServiceCode)
    assert(match == nil || match?.managedObjectContext != nil, "Service has no context!")
    return match
  }
  
}

// MARK: - TKRealTimeUpdatable

/// :nodoc:
extension Service: TKRealTimeUpdatable {
  public var wantsRealTimeUpdates: Bool {
    guard self.isRealTimeCapable else { return false }
    
    guard
      case .timetabled(_, let maybeDeparture)? = sortedVisits.first?.timing,
      let departure = maybeDeparture,
      case .timetabled(let maybeArrival, let maybeFallbackArrival)? = sortedVisits.last?.timing,
      let arrival = maybeArrival ?? maybeFallbackArrival
      else {
        return true // ask anyway
    }
    
    return wantsRealTimeUpdates(forStart: departure, end: arrival, forPreplanning: false)
  }
  
  public var objectForRealTimeUpdates: Any {
    return self
  }
  
  public var regionForRealTimeUpdates: TKRegion {
    return region ?? .international
  }
}

// MARK: - Flag accessors

extension Service {
  
  struct Flag: OptionSet {
    static let realTime               = Flag(rawValue: 1 << 0)
    static let realTimeCapable        = Flag(rawValue: 1 << 1)
    static let canceled               = Flag(rawValue: 1 << 2)
    static let bicycleAccessible      = Flag(rawValue: 1 << 3)
    static let wheelchairAccessible   = Flag(rawValue: 1 << 4)
    static let wheelchairInaccessible = Flag(rawValue: 1 << 5)
    
    let rawValue: Int16
  }
  
  private func set(_ flag: Flag, to value: Bool) {
    if value {
      flags = Flag(rawValue: flags).union(flag).rawValue
    } else {
      flags = Flag(rawValue: flags).subtracting(flag).rawValue
    }
  }
  
  @objc
  public var isRealTime: Bool {
    get { Flag(rawValue: flags).contains(.realTime) }
    set { set(.realTime, to: newValue) }
  }

  @objc
  public var isRealTimeCapable: Bool {
    get { Flag(rawValue: flags).contains(.realTimeCapable) }
    set { set(.realTimeCapable, to: newValue) }
  }

  @objc
  public var isCanceled: Bool {
    get { Flag(rawValue: flags).contains(.canceled) }
    set { set(.canceled, to: newValue) }
  }

  @objc
  public var isBicycleAccessible: Bool {
    get { Flag(rawValue: flags).contains(.bicycleAccessible) }
    set { set(.bicycleAccessible, to: newValue) }
  }
  
  var isWheelchairAccessible: Bool {
    get { Flag(rawValue: flags).contains(.wheelchairAccessible) }
    set { set(.wheelchairAccessible, to: newValue) }
  }

  var isWheelchairInaccessible: Bool {
    get { Flag(rawValue: flags).contains(.wheelchairInaccessible) }
    set { set(.wheelchairInaccessible, to: newValue) }
  }


}

// MARK: - Accessors

extension Service {
  
  public func allAlerts() -> [Alert] {
    guard let hashCodes = alertHashCodes, let context = managedObjectContext else { return [] }
    return hashCodes
      .compactMap { Alert.fetch(withHashCode: $0, inTripKitContext: context) }
      .sorted { $0.severity.intValue > $1.severity.intValue }
  }
  
  @objc public var region: TKRegion? {
    if let visit = visits?.first {
      return visit.stop.region
    } else {
      // we might not have visits if they got deleted in the mean-time
      return nil
    }
  }
  
  @objc public var hasServiceData: Bool {
    guard shape != nil, let visits = self.visits else { return false }
    return visits.count > 1
  }

  @objc public var isFrequencyBased: Bool {
    guard let frequency = self.frequency else { return false }
    return frequency.intValue > 0
  }

  @objc public var modeTitle: String? {
    return findModeInfo()?.alt.localizedCapitalized
  }
  
  @objc public func modeImage(for type: TKStyleModeIconType) -> TKImage? {
    return findModeInfo()?.image(type: type)
  }
  
  @objc public func modeImageURL(for type: TKStyleModeIconType) -> URL? {
    return findModeInfo()?.imageURL(type: type)
  }
  
  public var modeImageIsTemplate: Bool {
    return findModeInfo()?.remoteImageIsTemplate ?? false
  }

  @objc
  public func findModeInfo() -> TKModeInfo? {
    if let modeInfo = modeInfo {
      return modeInfo
    }
    for visit in visits ?? [] where visit.stop.stopModeInfo != nil {
      return visit.stop.stopModeInfo
    }
    for segment in segments ?? [] where segment.segmentTemplate?.modeInfo != nil {
      return segment.segmentTemplate?.modeInfo
    }

    TKLog.info("Got no mode, visits or segments!")
    return nil
  }

}
