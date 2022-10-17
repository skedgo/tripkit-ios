//
//  Vehicle+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData


extension Vehicle {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Vehicle> {
        return NSFetchRequest<Vehicle>(entityName: "Vehicle")
    }

    @NSManaged public var bearing: NSNumber?
    @NSManaged public var componentsData: Data?
    @NSManaged public var icon: String?
    @NSManaged public var identifier: String?
    @NSManaged public var label: String?
    @NSManaged public var lastUpdate: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged var segment: SegmentReference?
    @NSManaged var segmentAlternatives: Set<SegmentReference>?
    @NSManaged public var service: Service?
    @NSManaged public var serviceAlternatives: Set<Service>?

}

// MARK: Generated accessors for segmentAlternatives
extension Vehicle {

    @objc(addSegmentAlternativesObject:)
    @NSManaged func addToSegmentAlternatives(_ value: SegmentReference)

    @objc(removeSegmentAlternativesObject:)
    @NSManaged func removeFromSegmentAlternatives(_ value: SegmentReference)

    @objc(addSegmentAlternatives:)
    @NSManaged func addToSegmentAlternatives(_ values: NSSet)

    @objc(removeSegmentAlternatives:)
    @NSManaged func removeFromSegmentAlternatives(_ values: NSSet)

}

// MARK: Generated accessors for serviceAlternatives
extension Vehicle {

    @objc(addServiceAlternativesObject:)
    @NSManaged func addToServiceAlternatives(_ value: Service)

    @objc(removeServiceAlternativesObject:)
    @NSManaged func removeFromServiceAlternatives(_ value: Service)

    @objc(addServiceAlternatives:)
    @NSManaged func addToServiceAlternatives(_ values: NSSet)

    @objc(removeServiceAlternatives:)
    @NSManaged func removeFromServiceAlternatives(_ values: NSSet)

}

#endif
