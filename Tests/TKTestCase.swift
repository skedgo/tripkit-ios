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

@testable import TripKit

extension XCTestCase {
  
  var bundle: Bundle { return Bundle(for: TKTestCase.self) }
  
  func dataFromJSON(named name: String) throws -> Data {
    let filePath = bundle.path(forResource: name, ofType: "json")
    return try Data(contentsOf: URL(fileURLWithPath: filePath!))
  }
  
  
  func contentFromJSON<R>(named name: String) throws -> R {
    let data = try dataFromJSON(named: name)
    let result = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? R
    return try result.orThrow(NSError(code: 678123, message: "Could not convert JSON to \(R.Type.self)"))
  }
  
}

class TKTestCase: XCTestCase {
  
  var tripKitContext: NSManagedObjectContext!
  
  override func setUp() {
    super.setUp()
    
    // TripKit context
    let model = TripKit.model
    let tripKitCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    _ = try! tripKitCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = tripKitCoordinator
    
    self.tripKitContext = context
  }
  
  override func tearDown() {
    super.tearDown()
    tripKitContext = nil
  }

  func trip(fromFilename filename: String, serviceFilename: String? = nil) -> Trip {
    
    let observable = Observable<Trip>.create { observer in
      let tripJson: [String: Any] = try! self.contentFromJSON(named: filename)
      let parser = TKRoutingParser(tripKitContext: self.tripKitContext)
      parser.parseAndAddResult(tripJson) { request in
        guard let trip = request?.tripGroups?.first?.visibleTrip else { preconditionFailure() }
        
        if let serviceFilename = serviceFilename {
          for segment in trip.segments {
            if let service = segment.service {
              let serviceJson: [String: Any] = try! self.contentFromJSON(named: serviceFilename)
              let provider = TKBuzzInfoProvider()
              provider.addContent(to: service, fromResponse: serviceJson)
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
