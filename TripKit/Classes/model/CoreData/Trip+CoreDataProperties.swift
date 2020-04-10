//
//  Trip+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 09.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension Trip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var arrivalTime: Date
    @NSManaged public var budgetPoints: NSNumber?
    @NSManaged public var currencyCode: String?

    /// :nodoc:
    @NSManaged public var data: Data? // Data with an encoded dictionary

    @NSManaged public var departureTime: Date

    /// :nodoc:
    @NSManaged public var flags: Int16
    @NSManaged public var logURLString: String?
    @NSManaged public var mainSegmentHashCode: Int32
    @NSManaged public var minutes: Int16 // cache for sorting
    @NSManaged public var plannedURLString: String?
    @NSManaged public var progressURLString: String?
    @NSManaged public var saveURLString: String?
    @NSManaged public var shareURLString: String?
    @NSManaged public var temporaryURLString: String?
    @NSManaged public var totalCalories: Float
    @NSManaged public var totalCarbon: Float
    @NSManaged public var totalHassle: Float
    @NSManaged public var totalPrice: NSNumber?
    @NSManaged public var totalPriceUSD: NSNumber?
    @NSManaged public var totalScore: Float
    @NSManaged public var totalWalking: Float
    @NSManaged public var updateURLString: String?
    @NSManaged public var representedGroup: TripGroup?

    /// :nodoc:
    @NSManaged public var segmentReferences: NSSet?

    @NSManaged public var tripGroup: TripGroup

}

// MARK: Generated accessors for segmentReferences
extension Trip {

    @objc(addSegmentReferencesObject:)
    @NSManaged public func addToSegmentReferences(_ value: SegmentReference)

    @objc(removeSegmentReferencesObject:)
    @NSManaged public func removeFromSegmentReferences(_ value: SegmentReference)

    @objc(addSegmentReferences:)
    @NSManaged public func addToSegmentReferences(_ values: NSSet)

    @objc(removeSegmentReferences:)
    @NSManaged public func removeFromSegmentReferences(_ values: NSSet)

}
