//
//  Service+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData


extension Service {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Service> {
        return NSFetchRequest<Service>(entityName: "Service")
    }

    @NSManaged var alertHashCodes: [NSNumber]?
    @NSManaged public var code: String
    @NSManaged public var color: TKColor?
    @NSManaged var flags: Int16
    @NSManaged public var frequency: NSNumber?
    @NSManaged public var modeInfo: TKModeInfo?
    @NSManaged public var name: String?
    @NSManaged public var number: String?
    @NSManaged public var operatorID: String?
    @NSManaged public var operatorName: String?
    @NSManaged public var continuation: Service?
    @NSManaged public var progenitor: Service?
    @NSManaged var segments: Set<SegmentReference>?
    @NSManaged public var shape: Shape?
    @NSManaged public var vehicle: Vehicle?
    @NSManaged public var vehicleAlternatives: Set<Vehicle>?
    @NSManaged public var visits: Set<StopVisits>?

}

// MARK: Generated accessors for segments
extension Service {

    @objc(addSegmentsObject:)
    @NSManaged func addToSegments(_ value: SegmentReference)

    @objc(removeSegmentsObject:)
    @NSManaged func removeFromSegments(_ value: SegmentReference)

    @objc(addSegments:)
    @NSManaged func addToSegments(_ values: NSSet)

    @objc(removeSegments:)
    @NSManaged func removeFromSegments(_ values: NSSet)

}

// MARK: Generated accessors for vehicleAlternatives
extension Service {

    @objc(addVehicleAlternativesObject:)
    @NSManaged func addToVehicleAlternatives(_ value: Vehicle)

    @objc(removeVehicleAlternativesObject:)
    @NSManaged func removeFromVehicleAlternatives(_ value: Vehicle)

    @objc(addVehicleAlternatives:)
    @NSManaged func addToVehicleAlternatives(_ values: NSSet)

    @objc(removeVehicleAlternatives:)
    @NSManaged func removeFromVehicleAlternatives(_ values: NSSet)

}

// MARK: Generated accessors for visits
extension Service {

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
