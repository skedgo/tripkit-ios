//
//  Shape+CoreDataProperties.swift
//  
//
//  Created by Adrian Schönig on 27.03.20.
//
//

import Foundation
import CoreData


extension Shape {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shape> {
        return NSFetchRequest<Shape>(entityName: "Shape")
    }

    @NSManaged public var encodedWaypoints: String?
    @NSManaged public var flags: Int32
    @NSManaged public var index: Int16
    @NSManaged public var metres: NSNumber?
    @NSManaged public var title: String?
    @NSManaged public var travelled: Bool
    @NSManaged public var rawInstruction: Int16
    @NSManaged public var services: Set<Service>?
    @NSManaged public var template: SegmentTemplate?
    @NSManaged public var visits: Set<StopVisits>?
  
    @NSManaged public var data: Data?

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
