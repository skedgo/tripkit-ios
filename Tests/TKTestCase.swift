//
//  TGTestCase.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import XCTest
import CoreData

import RxSwift
import RxBlocking

@testable import TripKit

extension XCTestCase {
  
  var bundle: Bundle { return Bundle(for: TKTestCase.self) }
  
  func dataFromJSON(named name: String) throws -> Data {
    let filePath = bundle.path(forResource: name, ofType: "json")
    return try Data(contentsOf: URL(fileURLWithPath: filePath!))
  }
  
  
  func contentFromJSON(named name: String) throws -> Any {
    let data = try dataFromJSON(named: name)
    return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
  }
  
}

class TKTestCase: XCTestCase {
  
  var tripKitContext: NSManagedObjectContext!
  
  var tripKitModel: NSManagedObjectModel {
    return TKTripKit.tripKitModel()
  }
  
  override func setUp() {
    super.setUp()
    
    // TripKit context
    let tripKitCoordinator = NSPersistentStoreCoordinator(managedObjectModel: tripKitModel)
    _ = try! tripKitCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
    tripKitContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    tripKitContext.persistentStoreCoordinator = tripKitCoordinator
  }

  func trip(fromFilename filename: String, serviceFilename: String? = nil) -> Trip {
    
    let observable = Observable<Trip>.create { observer in
      let tripJson = try! self.contentFromJSON(named: filename)
      let parser = TKRoutingParser(tripKitContext: self.tripKitContext)
      parser.parseAndAddResult(tripJson as! [AnyHashable : Any]) { request in
        guard let trip = request?.tripGroups?.first?.visibleTrip else { preconditionFailure() }
        
        if let serviceFilename = serviceFilename {
          for segment in trip.segments() {
            if let service = segment.service() {
              let serviceJson = try! self.contentFromJSON(named: serviceFilename)
              let provider = TKBuzzInfoProvider()
              provider.addContent(to: service, fromResponse: serviceJson as! [AnyHashable : Any])
              break
            }
          }
        }
        observer.onNext(trip)
        observer.onCompleted()
      }
      return Disposables.create()
    }
    return try! observable.toBlocking().first()!
  }
  
  func testThatEnvironmentWorks() {
    XCTAssertNotNil(tripKitContext)
    XCTAssertNotNil(tripKitContext.persistentStoreCoordinator)
  }
}
