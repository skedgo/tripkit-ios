//
//  TripGroup+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension TripGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TripGroup> {
        return NSFetchRequest<TripGroup>(entityName: "TripGroup")
    }

    @NSManaged public var classification: String?
    @NSManaged var flags: Int16
    @NSManaged public var frequency: NSNumber?
    @NSManaged var sourcesRaw: Array<NSCoding & NSObjectProtocol>?
    @NSManaged var visibilityRaw: Int16
    @NSManaged var preferredFor: Set<TripRequest>?
    @NSManaged public var request: TripRequest!
    @NSManaged public var trips: Set<Trip>!
    @NSManaged public var visibleTrip: Trip?

}

// MARK: Generated accessors for preferredFor
extension TripGroup {

    @objc(addPreferredForObject:)
    @NSManaged func addToPreferredFor(_ value: TripRequest)

    @objc(removePreferredForObject:)
    @NSManaged func removeFromPreferredFor(_ value: TripRequest)

    @objc(addPreferredFor:)
    @NSManaged func addToPreferredFor(_ values: NSSet)

    @objc(removePreferredFor:)
    @NSManaged func removeFromPreferredFor(_ values: NSSet)

}

// MARK: Generated accessors for trips
extension TripGroup {

    @objc(addTripsObject:)
    @NSManaged func addToTrips(_ value: Trip)

    @objc(removeTripsObject:)
    @NSManaged func removeFromTrips(_ value: Trip)

    @objc(addTrips:)
    @NSManaged func addToTrips(_ values: NSSet)

    @objc(removeTrips:)
    @NSManaged func removeFromTrips(_ values: NSSet)

}
