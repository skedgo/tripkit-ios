//
//  StopLocation+CoreDataClass.swift
//  
//
//  Created by Adrian Schönig on 09.04.20.
//
//

import Foundation
import CoreData

/// Represents a public transport location
@objc(StopLocation)
public class StopLocation: NSManagedObject {

  /// :nodoc:
  var lastStopVisit: StopVisits?
  
  /// :nodoc:
  var lastEarliestDate: Date?
  
  // MARK: - Fetcher
  
  /// :nodoc:
  @objc(fetchStopForStopCode:inRegionNamed:requireCoordinate:inTripKitContext:)
  public static func fetchStop(stopCode: String, inRegion regionName: String?, requireCoordinate: Bool, in context: NSManagedObjectContext) -> StopLocation? {
    guard let regionName = regionName else { return nil }
    
    let predicate = requireCoordinate
      ? NSPredicate(format: "stopCode = %@ AND regionName = %@ AND location != nil", stopCode, regionName)
      : NSPredicate(format: "stopCode = %@ AND regionName = %@", stopCode, regionName)
    if let stop = context.fetchUniqueObject(StopLocation.self, predicate: predicate) {
      return stop
    }
    
    // region name might be missing, just match on stop code which might give you the wrong stop but it's unlikely.
    return context.fetchUniqueObject(StopLocation.self, predicate: NSPredicate(format: "stopCode = %@", stopCode))
  }

  @objc(fetchOrInsertStopForStopCode:inRegionNamed:intoTripKitContext:)
  static func fetchOrInsertStop(stopCode: String, inRegion regionName: String, in context: NSManagedObjectContext) -> StopLocation {
    let stop = fetchOrInsertStop(stopCode: stopCode, modeInfo: nil, at: nil, in: context)
    stop.regionName = regionName
    return stop
  }

  /// :nodoc:
  @objc(fetchOrInsertStopForStopCode:modeInfo:atLocation:intoTripKitContext:)
  public static func fetchOrInsertStop(stopCode: String, modeInfo: TKModeInfo? = nil, at location: TKNamedCoordinate? = nil, in context: NSManagedObjectContext) -> StopLocation {
    var stop: StopLocation?
    var region: TKRegion?
    if let location = location, let anyRegion = location.regions.first {
      stop = fetchStop(stopCode: stopCode, inRegion: anyRegion.name, requireCoordinate: false, in: context)
      region = anyRegion
    }
      
    if let stop = stop {
      stop.name = location?.title
      stop.location = location
      stop.stopCode = stopCode
      stop.stopModeInfo = modeInfo ?? stop.stopModeInfo
      stop.regionName = region?.name
      return stop
    } else {
      let stop = insertStop(stopCode: stopCode, modeInfo: modeInfo, at: location, in: context)
      stop.regionName = region?.name
      return stop
    }
  }
  
  @objc(insertStopForStopCode:modeInfo:atLocation:intoTripKitContext:)
  static func insertStop(stopCode: String, modeInfo: TKModeInfo? = nil, at location: TKNamedCoordinate? = nil, in context: NSManagedObjectContext) -> StopLocation {
    let stop = StopLocation(context: context)
    stop.name = location?.title
    stop.location = location
    stop.stopCode = stopCode
    stop.stopModeInfo = modeInfo
    return stop
  }
  
  @objc
  func departuresPredicate(from date: Date?) -> NSPredicate? {
    guard let date = date else { return nil }
    let stops = stopsToMatchTo()
    return StopVisits.departuresPredicate(forStops: stops, from: date, filter: self.filter)
  }
  
  /// Stops to for displaying a timetable for this stop – includes its children
  public func stopsToMatchTo() -> [StopLocation] {
    if let children = children, children.count > 0 {
      return Array(children)
    } else {
      return [self]
    }
  }
  
  /// Deletes all `StopVisits` associated with this stop, including its children
  public func clearVisits() {
    guard let context = managedObjectContext else { return }
    
    visits?
      .filter { $0.isActive == false }
      .forEach(context.delete)
    
    children?
      .forEach { $0.clearVisits() }
  }

  
  
}
