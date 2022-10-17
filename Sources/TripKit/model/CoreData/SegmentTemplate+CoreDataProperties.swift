//
//  SegmentTemplate+CoreDataProperties.swift
//  
//
//  Created by Adrian Schönig on 05.04.18.
//
//

#if canImport(CoreData)

import Foundation
import CoreData


extension SegmentTemplate {

    @nonobjc class func fetchRequest() -> NSFetchRequest<SegmentTemplate> {
        return NSFetchRequest<SegmentTemplate>(entityName: "SegmentTemplate")
    }

    @NSManaged var action: String?
    @NSManaged var bearing: NSNumber?
    @NSManaged var data: Data? // NSData (previously NSDictionary / NSMutableDictionary)
    @NSManaged var durationWithoutTraffic: NSNumber?
    @NSManaged var endLocation: NSObject?
    @NSManaged var flags: NSNumber?
    @NSManaged var hashCode: NSNumber?
    @NSManaged var metres: NSNumber?
    @NSManaged var metresDismount: NSNumber?
    @NSManaged var metresFriendly: NSNumber?
    @NSManaged var metresUnfriendly: NSNumber?
    @NSManaged var modeIdentifier: String!
    @NSManaged var notesRaw: String?
    @NSManaged var scheduledEndStopCode: String?
    @NSManaged var scheduledStartStopCode: String?
    @NSManaged var segmentType: NSNumber?
    @NSManaged var smsMessage: String?
    @NSManaged var smsNumber: String?
    @NSManaged var startLocation: NSObject?
    @NSManaged var visibility: NSNumber?
    @NSManaged var references: NSSet?
  
    /// Shapes define a sequence of waypoints. A segment can have a couple of those, e.g., a number of streets, or a bus line for which only a part is travelled along.
    @NSManaged var shapes: NSSet?

}

// MARK: Generated accessors for references
extension SegmentTemplate {

    @objc(addReferencesObject:)
    @NSManaged func addToReferences(_ value: SegmentReference)

    @objc(removeReferencesObject:)
    @NSManaged func removeFromReferences(_ value: SegmentReference)

    @objc(addReferences:)
    @NSManaged func addToReferences(_ values: NSSet)

    @objc(removeReferences:)
    @NSManaged func removeFromReferences(_ values: NSSet)

}

// MARK: Generated accessors for shapes
extension SegmentTemplate {

    @objc(addShapesObject:)
    @NSManaged func addToShapes(_ value: Shape)

    @objc(removeShapesObject:)
    @NSManaged func removeFromShapes(_ value: Shape)

    @objc(addShapes:)
    @NSManaged func addToShapes(_ values: NSSet)

    @objc(removeShapes:)
    @NSManaged func removeFromShapes(_ values: NSSet)

}

#endif
