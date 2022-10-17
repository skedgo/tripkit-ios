//
//  TripRequest+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData


extension TripRequest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TripRequest> {
        return NSFetchRequest<TripRequest>(entityName: "TripRequest")
    }

    @NSManaged public var arrivalTime: Date?
    @NSManaged public var departureTime: Date?
    @NSManaged public var excludedStops: [String]?
    @NSManaged public var expandForFavorite: Bool
    @NSManaged public var fromLocation: TKNamedCoordinate!
    @NSManaged public var purpose: String?
    @NSManaged public var timeCreated: Date?
    @NSManaged var timeType: Int16
    @NSManaged public var toLocation: TKNamedCoordinate!
    @NSManaged public var preferredGroup: TripGroup?
    @NSManaged public var tripGroups: Set<TripGroup>

}

// MARK: Generated accessors for tripGroups
extension TripRequest {

    @objc(addTripGroupsObject:)
    @NSManaged func addToTripGroups(_ value: TripGroup)

    @objc(removeTripGroupsObject:)
    @NSManaged func removeFromTripGroups(_ value: TripGroup)

    @objc(addTripGroups:)
    @NSManaged func addToTripGroups(_ values: NSSet)

    @objc(removeTripGroups:)
    @NSManaged func removeFromTripGroups(_ values: NSSet)

}

#endif
