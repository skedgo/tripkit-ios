//
//  DLSEntry+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension DLSEntry {
  
  @nonobjc public class func fetchRequest() -> NSFetchRequest<DLSEntry> {
    return NSFetchRequest<DLSEntry>(entityName: "DLSEntry")
  }
  
  /// Indexed identifier to quickly look up entries for a particular pair of stops.
  @NSManaged var pairIdentifier: String
  
  /// The destination. It should not be a parent stop. The time to get off is the `arrival` of this `DLSEntry`.
  ///
  /// - See `StopVisits` superclass
  @NSManaged public var endStop: StopLocation
  
  @NSManaged public var endPlatform: String?
  @NSManaged public var timetableEndPlatform: String?
  
}
