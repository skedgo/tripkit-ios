//
//  DLSEntry+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData

/**
 A `DLSEntry` represents the connection of a particular service starting at a particular stop and going all the way an end stop without the passanger having to get off.
 
 - note: The _arrival_ represents arriving at the `endStop` not arriving at the starting `stop` as is the case for usual instances of `StopVisits`. This means that `arrival` is always after (or at the same time as) as `departure`.
 
 - note: The `service` might not be the same when arriving at `endStop` but it can instead be one of the start's
 */
@objc(DLSEntry)
public class DLSEntry: StopVisits {

}

extension DLSEntry {
  
  /// Creates a predicate to query the database for DLS entries for the specified list of pair identifiers after the given date and using the specific filter.
  ///
  /// - Parameters:
  ///   - pairs: Strings matched against the `pairIdentifier` of the DLS entries.
  ///   - date: Starting date and time.
  ///   - filter: Filter which the returnes DLS entries must match.
  /// - Returns: Predicate to query CoreData with
  public static func departuresPredicate(pairs: Set<String>, from date: Date, filter: String = "") -> NSPredicate {
    if filter.isEmpty {
      return NSPredicate(format: "pairIdentifier IN %@ AND departure != nil AND departure > %@", pairs, date as CVarArg)
    } else {
      return NSPredicate(format: "pairIdentifier IN %@ AND departure != nil AND departure > %@ AND (service.number CONTAINS[c] %@ OR service.name CONTAINS[c] %@ OR stop.shortName CONTAINS[c] %@ OR searchString CONTAINS[c] %@)", pairs, date as CVarArg, filter, filter, filter, filter)
    }
  }
  
  public static func fetchDLSEntries(pairs: Set<String>, from date: Date, limit: Int, in context: NSManagedObjectContext) -> [DLSEntry] {
    let request: NSFetchRequest<DLSEntry> = DLSEntry.fetchRequest()
    request.predicate = departuresPredicate(pairs: pairs, from: date)
    request.sortDescriptors = StopVisits.defaultSortDescriptors
    request.fetchLimit = limit
    do {
      let result = try context.fetch(request)
      return result
    } catch {
      TKLog.warn("Error while fetching DLS entries: \(error)")
      return []
    }
  }
  
  public static func clearAllEntries(in context: NSManagedObjectContext) {
    let objects = context.fetchObjects(DLSEntry.self)
    objects.forEach(context.delete)
  }
  
}

extension DLSEntry {
  @objc public override var wantsRealTimeUpdates: Bool {
    guard service.isRealTimeCapable,
      case .timetabled(let maybeArrival, let maybeDeparture) = timing,
      let departure = maybeDeparture,
      let arrival = maybeArrival else { return false }
    return wantsRealTimeUpdates(forStart: departure, end: arrival, forPreplanning: false)
  }
  
  public var arrivalPlatform: String? {
    endPlatform?.trimmedNonEmpty ?? endStop.shortName?.trimmedNonEmpty
  }

}

#endif
