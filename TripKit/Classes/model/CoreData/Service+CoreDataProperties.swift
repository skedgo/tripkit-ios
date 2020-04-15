//
//  Service+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 10.04.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension Service {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Service> {
        return NSFetchRequest<Service>(entityName: "Service")
    }

    @NSManaged public var alertHashCodes: [NSNumber]?
    @NSManaged public var code: String
    @NSManaged public var color: TKColor?

    /// :nodoc:
    @NSManaged public var flags: Int16

    @NSManaged public var frequency: NSNumber?
    @NSManaged public var modeInfo: TKModeInfo?
    @NSManaged public var name: String?
    @NSManaged public var number: String?
    @NSManaged public var operatorID: String?
    @NSManaged public var operatorName: String?
    @NSManaged public var continuation: Service?
    @NSManaged public var progenitor: Service?
    @NSManaged public var segments: Set<SegmentReference>?
    @NSManaged public var shape: Shape?
    @NSManaged public var vehicle: Vehicle?
    @NSManaged public var vehicleAlternatives: Set<Vehicle>?
    @NSManaged public var visits: Set<StopVisits>?

}

// MARK: Generated accessors for segments
extension Service {

    @objc(addSegmentsObject:)
    @NSManaged public func addToSegments(_ value: SegmentReference)

    @objc(removeSegmentsObject:)
    @NSManaged public func removeFromSegments(_ value: SegmentReference)

    @objc(addSegments:)
    @NSManaged public func addToSegments(_ values: NSSet)

    @objc(removeSegments:)
    @NSManaged public func removeFromSegments(_ values: NSSet)

}

// MARK: Generated accessors for vehicleAlternatives
extension Service {

    @objc(addVehicleAlternativesObject:)
    @NSManaged public func addToVehicleAlternatives(_ value: Vehicle)

    @objc(removeVehicleAlternativesObject:)
    @NSManaged public func removeFromVehicleAlternatives(_ value: Vehicle)

    @objc(addVehicleAlternatives:)
    @NSManaged public func addToVehicleAlternatives(_ values: NSSet)

    @objc(removeVehicleAlternatives:)
    @NSManaged public func removeFromVehicleAlternatives(_ values: NSSet)

}

// MARK: Generated accessors for visits
extension Service {

    @objc(addVisitsObject:)
    @NSManaged public func addToVisits(_ value: StopVisits)

    @objc(removeVisitsObject:)
    @NSManaged public func removeFromVisits(_ value: StopVisits)

    @objc(addVisits:)
    @NSManaged public func addToVisits(_ values: NSSet)

    @objc(removeVisits:)
    @NSManaged public func removeFromVisits(_ values: NSSet)

}
