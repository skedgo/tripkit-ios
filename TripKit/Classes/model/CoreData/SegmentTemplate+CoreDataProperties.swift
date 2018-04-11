//
//  SegmentTemplate+CoreDataProperties.swift
//  
//
//  Created by Adrian Schönig on 05.04.18.
//
//

import Foundation
import CoreData


extension SegmentTemplate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SegmentTemplate> {
        return NSFetchRequest<SegmentTemplate>(entityName: "SegmentTemplate")
    }

    @NSManaged public var action: String?
    @NSManaged public var bearing: NSNumber?
    @NSManaged public var data: NSObject? // NSData (previously NSDictionary / NSMutableDictionary)
    @NSManaged public var durationWithoutTraffic: NSNumber?
    @NSManaged public var endLocation: NSObject?
    @NSManaged public var flags: NSNumber?
    @NSManaged public var hashCode: NSNumber?
    @NSManaged public var metres: NSNumber?
    @NSManaged public var metresDismount: NSNumber?
    @NSManaged public var metresFriendly: NSNumber?
    @NSManaged public var metresUnfriendly: NSNumber?
    @NSManaged public var modeIdentifier: String!
    @NSManaged public var notesRaw: String?
    @NSManaged public var scheduledEndStopCode: String?
    @NSManaged public var scheduledStartStopCode: String?
    @NSManaged public var segmentType: NSNumber?
    @NSManaged public var smsMessage: String?
    @NSManaged public var smsNumber: String?
    @NSManaged public var startLocation: NSObject?
    @NSManaged public var toDelete: NSNumber?
    @NSManaged public var visibility: NSNumber?
    @NSManaged public var references: NSSet?
  
    /// Shapes define a sequence of waypoints. A segment can have a couple of those, e.g., a number of streets, or a bus line for which only a part is travelled along.
    @NSManaged public var shapes: NSSet?

}

// MARK: Generated accessors for references
extension SegmentTemplate {

    @objc(addReferencesObject:)
    @NSManaged public func addToReferences(_ value: SegmentReference)

    @objc(removeReferencesObject:)
    @NSManaged public func removeFromReferences(_ value: SegmentReference)

    @objc(addReferences:)
    @NSManaged public func addToReferences(_ values: NSSet)

    @objc(removeReferences:)
    @NSManaged public func removeFromReferences(_ values: NSSet)

}

// MARK: Generated accessors for shapes
extension SegmentTemplate {

    @objc(addShapesObject:)
    @NSManaged public func addToShapes(_ value: Shape)

    @objc(removeShapesObject:)
    @NSManaged public func removeFromShapes(_ value: Shape)

    @objc(addShapes:)
    @NSManaged public func addToShapes(_ values: NSSet)

    @objc(removeShapes:)
    @NSManaged public func removeFromShapes(_ values: NSSet)

}
