//
//  Shape+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import CoreData


extension Shape {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shape> {
        return NSFetchRequest<Shape>(entityName: "Shape")
    }

    @NSManaged public var encodedWaypoints: String?
    @NSManaged public var friendly: NSNumber?
    @NSManaged public var index: NSNumber?
    @NSManaged public var title: String?
    @NSManaged public var toDelete: NSNumber?
    @NSManaged public var travelled: NSNumber?
    @NSManaged public var services: NSSet?
    @NSManaged public var template: SegmentTemplate?
    @NSManaged public var visits: NSSet?

}

// MARK: Generated accessors for services
extension Shape {

    @objc(addServicesObject:)
    @NSManaged public func addToServices(_ value: Service)

    @objc(removeServicesObject:)
    @NSManaged public func removeFromServices(_ value: Service)

    @objc(addServices:)
    @NSManaged public func addToServices(_ values: NSSet)

    @objc(removeServices:)
    @NSManaged public func removeFromServices(_ values: NSSet)

}

// MARK: Generated accessors for visits
extension Shape {

    @objc(addVisitsObject:)
    @NSManaged public func addToVisits(_ value: StopVisits)

    @objc(removeVisitsObject:)
    @NSManaged public func removeFromVisits(_ value: StopVisits)

    @objc(addVisits:)
    @NSManaged public func addToVisits(_ values: NSSet)

    @objc(removeVisits:)
    @NSManaged public func removeFromVisits(_ values: NSSet)

}
