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

class TKTestCase: XCTestCase {
  
  var tripKitContext: NSManagedObjectContext!
  let bundle = Bundle(for: TKTestCase.self)
  
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

  func dataFromJSON(named name: String) -> Data? {
    let filePath = bundle.path(forResource: name, ofType: "json")
    return try? Data(contentsOf: URL(fileURLWithPath: filePath!))
  }

  
  func contentFromJSON(named name: String) -> Any {
    let data = dataFromJSON(named: name)
    let object: Any? = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0))
    return object!
  }
  
  func trip(fromFilename filename: String, serviceFilename: String? = nil) -> Trip {
    
    let observable = Observable<Trip>.create { observer in
      let tripJson = self.contentFromJSON(named: filename)
      let parser = TKRoutingParser(tripKitContext: self.tripKitContext)
      parser.parseAndAddResult(tripJson as! [AnyHashable : Any]) { request in
        guard let trip = request?.tripGroups?.first?.visibleTrip else { preconditionFailure() }
        
        if let serviceFilename = serviceFilename {
          for segment in trip.segments() {
            if let service = segment.service() {
              let serviceJson = self.contentFromJSON(named: serviceFilename)
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
