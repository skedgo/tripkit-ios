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
  
  convenience init(into context: NSManagedObjectContext) {
    if #available(iOS 10.0, macOS 10.12, *) {
      self.init(context: context)
    } else {
      self.init(entity: NSEntityDescription.entity(forEntityName: "Service", in: context)!, insertInto: context)
    }
  }
  
  @objc(fetchOrInsertServiceWithCode:inTripKitContext:)
  public static func fetchOrInsert(code: String, in context: NSManagedObjectContext) -> Service {
    if let existing = fetchExistingService(code: code, in: context) {
      return existing
    }
    
    let service = Service(into: context)
    service.code = code
    return service
  }
  
  @objc(fetchExistingServiceWithCode:inTripKitContext:)
  public static func fetchExistingService(code: String, in context: NSManagedObjectContext) -> Service? {
    
    let equalServiceCode = NSPredicate(format: "toDelete = NO AND code = %@", code)
    let match = context.fetchUniqueObject(Service.self, predicate: equalServiceCode)
    assert(match == nil || match?.managedObjectContext != nil, "Service has no context!")
    return match
  }
  
  @objc(removeServicesBeforeDate:fromManagedObjectContext:)
  public static func removeServices(before date: Date, from context: NSManagedObjectContext) {
    
    let withUpcomingDepartures = NSPredicate(format: "toDelete = NO AND (NONE visits.departure > %@)", date as CVarArg)
    for service in context.fetchObjects(Service.self, predicate: withUpcomingDepartures) {
      if let segments = service.segments, !segments.isEmpty {
        TKLog.debug("Service", text: "Keeping service \(service.lineName ?? "") as it has \(segments.count) segments.")
      } else {
        service.remove()
      }
    }
    
  }
  
}

// MARK: - TKRealTimeUpdatable

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

// MARK: - Helpers

extension Service {
  
  @objc public var region: TKRegion? {
    if let visit = visits?.first {
      return visit.stop.region
    } else {
      // we might not have visits if they got deleted in the mean-time
      return nil
    }
  }
  
  @objc public var modeTitle: String? {
    return findModeInfo()?.alt
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

  private func findModeInfo() -> TKModeInfo? {
    if let modeInfo = modeInfo {
      return modeInfo
    }
    for visit in visits ?? [] where visit.stop.stopModeInfo != nil {
      return visit.stop.stopModeInfo
    }
    for segment in segments ?? [] where segment.segmentTemplate?.modeInfo != nil {
      return segment.segmentTemplate?.modeInfo
    }

    assertionFailure("Got no mode, visits or segments!")
    return nil
  }

}
