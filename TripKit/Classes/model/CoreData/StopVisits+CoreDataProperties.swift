//
//  StopVisits+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension StopVisits {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StopVisits> {
        return NSFetchRequest<StopVisits>(entityName: "StopVisits")
    }

    /// - warn: Ambiguous. Use .timing instead
    @NSManaged var arrival: Date?
  
    @NSManaged public var bearing: NSNumber?
    
    /// - warn: Ambiguous. Use .timing instead
    /// :nodoc:
    @NSManaged public var departure: Date?
  
    @NSManaged var flags: Int16
    
    /// Defaults to `-1` if not (properly) set
    @NSManaged public var index: Int16
    
    @NSManaged public var isActive: Bool
    @NSManaged public var originalTime: Date?
    @NSManaged public var regionDay: Date?
    @NSManaged public var searchString: String?
    @NSManaged public var service: Service!
    @NSManaged public var shapes: Set<Shape>?
    @NSManaged public var stop: StopLocation!

}

// MARK: Generated accessors for shapes
extension StopVisits {

    @objc(addShapesObject:)
    @NSManaged func addToShapes(_ value: Shape)

    @objc(removeShapesObject:)
    @NSManaged func removeFromShapes(_ value: Shape)

    @objc(addShapes:)
    @NSManaged func addToShapes(_ values: NSSet)

    @objc(removeShapes:)
    @NSManaged func removeFromShapes(_ values: NSSet)

}
