//
//  SegmentReference+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension SegmentReference {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SegmentReference> {
        return NSFetchRequest<SegmentReference>(entityName: "SegmentReference")
    }

    @NSManaged public var alertHashCodes: Array<NSNumber>?
    @NSManaged public var bookingHashCode: Int32
    @NSManaged public var data: Data?
    @NSManaged public var endTime: Date!
    @NSManaged public var flags: Int16
    @NSManaged public var index: Int16
    @NSManaged public var startTime: Date!
    @NSManaged public var templateHashCode: NSNumber?
    @NSManaged public var realTimeVehicle: Vehicle?
    @NSManaged public var realTimeVehicleAlternatives: Set<Vehicle>?
    @NSManaged public var segmentTemplate: SegmentTemplate?
    @NSManaged public var service: Service?
    @NSManaged public var trip: Trip?

}

// MARK: Generated accessors for realTimeVehicleAlternatives
extension SegmentReference {

    @objc(addRealTimeVehicleAlternativesObject:)
    @NSManaged func addToRealTimeVehicleAlternatives(_ value: Vehicle)

    @objc(removeRealTimeVehicleAlternativesObject:)
    @NSManaged func removeFromRealTimeVehicleAlternatives(_ value: Vehicle)

    @objc(addRealTimeVehicleAlternatives:)
    @NSManaged func addToRealTimeVehicleAlternatives(_ values: NSSet)

    @objc(removeRealTimeVehicleAlternatives:)
    @NSManaged func removeFromRealTimeVehicleAlternatives(_ values: NSSet)

}
