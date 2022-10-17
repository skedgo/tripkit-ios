//
//  Trip+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData


extension Trip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var arrivalTime: Date!
    @NSManaged public var budgetPoints: NSNumber?
    @NSManaged public var currencyCode: String?

    @NSManaged var data: Data? // Data with an encoded dictionary

    @NSManaged public var departureTime: Date!

    @NSManaged var flags: Int16
    @NSManaged public var logURLString: String?
    @NSManaged var mainSegmentHashCode: Int32
    @NSManaged public var minutes: Int16 // cache for sorting
    @NSManaged public var plannedURLString: String?
    @NSManaged public var progressURLString: String?
    @NSManaged var saveURLString: String?
    @NSManaged var shareURLString: String?
    @NSManaged public var temporaryURLString: String?
    @NSManaged public var totalCalories: Float
    @NSManaged public var totalCarbon: Float
    @NSManaged public var totalHassle: Float
    @NSManaged public var totalPrice: NSNumber?
    @NSManaged public var totalPriceUSD: NSNumber?
    @NSManaged public var totalScore: Float
    @NSManaged public var totalWalking: Float
    @NSManaged public var updateURLString: String?
    @NSManaged var representedGroup: TripGroup?

    @NSManaged var segmentReferences: Set<SegmentReference>?

    @NSManaged public var tripGroup: TripGroup

}

// MARK: Generated accessors for segmentReferences
extension Trip {

    @objc(addSegmentReferencesObject:)
    @NSManaged func addToSegmentReferences(_ value: SegmentReference)

    @objc(removeSegmentReferencesObject:)
    @NSManaged func removeFromSegmentReferences(_ value: SegmentReference)

    @objc(addSegmentReferences:)
    @NSManaged func addToSegmentReferences(_ values: NSSet)

    @objc(removeSegmentReferences:)
    @NSManaged func removeFromSegmentReferences(_ values: NSSet)

}

#endif
