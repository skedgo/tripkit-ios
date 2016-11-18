//
//  TKDLSTable.swift
//  Pods
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation
import CoreData

import SGCoreKit

// In Swift-land this would be a struct
public class TKDLSTable: NSObject {
  
  public let startStopCode: String
  public let endStopCode: String
  public let previousPairs: Set<AnyHashable>?
  public let startRegion: SVKRegion
  public let endRegion: SVKRegion
  public let tripKitContext: NSManagedObjectContext
  
  public init?(for segment: TKSegment) {
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
    previousPairs = segment.trip?.tripGroup.pairIdentifiers(forPublicSegment: segment)
    startRegion = segment.startRegion() ?? SVKInternationalRegion.sharedInstance()
    endRegion = segment.endRegion()     ?? SVKInternationalRegion.sharedInstance()
    tripKitContext = moc
  }
  
}
