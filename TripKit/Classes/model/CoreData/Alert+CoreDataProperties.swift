//
//  Alert+CoreDataProperties.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData


extension Alert {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Alert> {
        return NSFetchRequest<Alert>(entityName: "Alert")
    }

    @NSManaged public var action: NSDictionary?
    @NSManaged public var endTime: Date?
    @NSManaged public var hashCode: Int32
    @NSManaged public var idService: String?
    @NSManaged public var idStopCode: String?
    @NSManaged public var location: TKNamedCoordinate?
    @NSManaged public var remoteIcon: String?
    @NSManaged public var severity: Int16
    @NSManaged public var startTime: Date?
    @NSManaged public var text: String?
    @NSManaged public var title: String? // Not actually optional, but optional to match `MKAnnotation`
    @NSManaged public var url: String?

}
