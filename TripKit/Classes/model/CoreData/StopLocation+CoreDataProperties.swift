//
//  StopLocation+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 09.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension StopLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StopLocation> {
        return NSFetchRequest<StopLocation>(entityName: "StopLocation")
    }

    @NSManaged public var alertHashCodes: Array<NSNumber>?
    @NSManaged public var filter: String?
    @NSManaged public var location: TKNamedCoordinate?
    @NSManaged public var name: String?
    @NSManaged public var regionName: String?
    @NSManaged public var shortName: String?
    @NSManaged public var sortScore: NSNumber?
    @NSManaged public var stopCode: String
    @NSManaged public var stopModeInfo: TKModeInfo?

    /// :nodoc:
    @NSManaged public var wheelchairAccessible: NSNumber?

    /// Zone ID of this stop, as defined by GTFS. Useful for ticketing calculaations.
    @NSManaged public var zoneID: String?
    @NSManaged public var children: Set<StopLocation>?
    @NSManaged public var endVisits: Set<StopVisits>?
    @NSManaged public var parent: StopLocation?
    @NSManaged public var visits: Set<StopVisits>?

}

// MARK: Generated accessors for children
extension StopLocation {

    @objc(addChildrenObject:)
    @NSManaged public func addToChildren(_ value: StopLocation)

    @objc(removeChildrenObject:)
    @NSManaged public func removeFromChildren(_ value: StopLocation)

    @objc(addChildren:)
    @NSManaged public func addToChildren(_ values: NSSet)

    @objc(removeChildren:)
    @NSManaged public func removeFromChildren(_ values: NSSet)

}

// MARK: Generated accessors for endVisits
extension StopLocation {

    @objc(addEndVisitsObject:)
    @NSManaged public func addToEndVisits(_ value: DLSEntry)

    @objc(removeEndVisitsObject:)
    @NSManaged public func removeFromEndVisits(_ value: DLSEntry)

    @objc(addEndVisits:)
    @NSManaged public func addToEndVisits(_ values: NSSet)

    @objc(removeEndVisits:)
    @NSManaged public func removeFromEndVisits(_ values: NSSet)

}

// MARK: Generated accessors for visits
extension StopLocation {

    @objc(addVisitsObject:)
    @NSManaged public func addToVisits(_ value: StopVisits)

    @objc(removeVisitsObject:)
    @NSManaged public func removeFromVisits(_ value: StopVisits)

    @objc(addVisits:)
    @NSManaged public func addToVisits(_ values: NSSet)

    @objc(removeVisits:)
    @NSManaged public func removeFromVisits(_ values: NSSet)

}
