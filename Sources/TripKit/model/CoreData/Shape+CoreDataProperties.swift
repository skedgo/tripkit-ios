//
//  Shape+CoreDataProperties.swift
//  
//
//  Created by Adrian Schönig on 27.03.20.
//
//

#if canImport(CoreData)

import Foundation
import CoreData


extension Shape {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Shape> {
        return NSFetchRequest<Shape>(entityName: "Shape")
    }

    @NSManaged public var encodedWaypoints: String?
    @NSManaged var flags: Int32
    @NSManaged public var index: Int16
    @NSManaged public var metres: NSNumber?
    @NSManaged public var title: String?
    @NSManaged public var travelled: Bool
    @NSManaged var rawInstruction: Int16
    @NSManaged public var services: Set<Service>?
    @NSManaged var template: SegmentTemplate?
    @NSManaged public var visits: Set<StopVisits>?
  
    @NSManaged var data: Data?

}

// MARK: Generated accessors for services
extension Shape {

    @objc(addServicesObject:)
    @NSManaged func addToServices(_ value: Service)

    @objc(removeServicesObject:)
    @NSManaged func removeFromServices(_ value: Service)

    @objc(addServices:)
    @NSManaged func addToServices(_ values: NSSet)

    @objc(removeServices:)
    @NSManaged func removeFromServices(_ values: NSSet)

}

// MARK: Generated accessors for visits
extension Shape {

    @objc(addVisitsObject:)
    @NSManaged func addToVisits(_ value: StopVisits)

    @objc(removeVisitsObject:)
    @NSManaged func removeFromVisits(_ value: StopVisits)

    @objc(addVisits:)
    @NSManaged func addToVisits(_ values: NSSet)

    @objc(removeVisits:)
    @NSManaged func removeFromVisits(_ values: NSSet)

}

#endif
