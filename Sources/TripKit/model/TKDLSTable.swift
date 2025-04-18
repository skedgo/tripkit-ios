//
//  TKDLSTable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

#if canImport(CoreData)

import Foundation
import CoreData

public class TKDLSTable: NSObject {
  
  @objc public let startStopCode: String
  @objc public let endStopCode: String
  @objc public var pairIdentifiers: Set<String>?
  @objc public let startRegion: TKRegion
  @objc public let endRegion: TKRegion
  @objc public let tripKitContext: NSManagedObjectContext
  
  @objc public init?(for segment: TKSegment) {
    let endSegment = segment.finalSegmentIncludingContinuation()
    
    guard
      segment.isPublicTransport,
      let request = segment.trip?.request,
      let moc = request.managedObjectContext,
      let start = segment.scheduledStartStopCode,
      let end = endSegment.scheduledEndStopCode
      else {
        return nil
    }
    
    startStopCode = start
    endStopCode = end
    pairIdentifiers = segment.trip?.tripGroup.cachedPairIdentifier(for: segment)
    startRegion = segment.startRegion ?? TKInternationalRegion.shared
    endRegion = endSegment.endRegion  ?? TKInternationalRegion.shared
    tripKitContext = moc
  }
  
  public func addPairIdentifiers(_ pairs: Set<String>) {
    let set = pairIdentifiers ?? Set()
    pairIdentifiers = set.union(pairs)
  }
  
}

#endif
