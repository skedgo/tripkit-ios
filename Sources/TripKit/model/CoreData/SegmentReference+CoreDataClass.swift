//
//  SegmentReference+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData

/// A time-dependent pointer to the time-independent `SegmentTemplate`
@objc(SegmentReference)
class SegmentReference: NSManagedObject {
}

extension SegmentReference {

  var template: SegmentTemplate! {
    if let assigned = segmentTemplate {
      return assigned
    }
    guard let hashCode = self.templateHashCode, let context = managedObjectContext else {
      TKLog.debug("Invalid segment reference without a hash code: \(self)")
      return nil
    }
    
    // link up
    segmentTemplate = SegmentTemplate.fetchSegmentTemplate(withHashCode: hashCode.intValue, in: context)
    return segmentTemplate
    
  }
  
  func assign(_ vehicle: TKVehicular?) {
    vehicleUUID = vehicle?.vehicleID?.uuidString
  }
  
  func findVehicle(all: [TKVehicular]) -> TKVehicular? {
    guard let uuid = vehicleUUID else { return nil }
    return all.first { $0.vehicleID?.uuidString == uuid }
  }

  
}

#endif
