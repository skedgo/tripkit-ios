//
//  TKDLSTable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation
import CoreData

public class TKDLSTable: NSObject {
  
  @objc public let startStopCode: String
  @objc public let endStopCode: String
  @objc public var pairIdentifiers: Set<String>?
  @objc public let startRegion: SVKRegion
  @objc public let endRegion: SVKRegion
  @objc public let tripKitContext: NSManagedObjectContext
  
  @objc public init?(for segment: TKSegment) {
    guard
      let request = segment.trip?.request,
      let moc = request.managedObjectContext,
      let start = segment.scheduledStartStopCode(),
      let end = segment.scheduledEndStopCode()
      else {
        return nil
    }
    
    startStopCode = start
    endStopCode = end
    pairIdentifiers = segment.trip?.tripGroup.pairIdentifiers(forPublicSegment: segment)
    startRegion = segment.startRegion() ?? SVKInternationalRegion.shared
    endRegion = segment.endRegion()     ?? SVKInternationalRegion.shared
    tripKitContext = moc
  }
  
  public func addPairIdentifiers(_ pairs: Set<String>) {
    let set = pairIdentifiers ?? Set()
    pairIdentifiers = set.union(pairs)
  }
  
}
