//
//  TGTestCase.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import CoreData

@testable import TripKit

extension XCTestCase {
  
  var bundle: Bundle { return Bundle(for: TKTestCase.self) }
  
  func dataFromJSON(named name: String) throws -> Data {
    #if SWIFT_PACKAGE
    let thisSourceFile = URL(fileURLWithPath: #file)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let jsonPath = thisDirectory
      .appendingPathComponent("Data", isDirectory: true)
      .appendingPathComponent(name).appendingPathExtension("json")
    return try Data(contentsOf: jsonPath)
    #else
    let filePath = bundle.path(forResource: name, ofType: "json")
    return try Data(contentsOf: URL(fileURLWithPath: filePath!))
    #endif
  }
  
  
  func contentFromJSON<R>(named name: String) throws -> R {
    let data = try dataFromJSON(named: name)
    let result = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? R
    return try result.orThrow(NSError(code: 678123, message: "Could not convert JSON to \(R.Type.self)"))
  }
  
}

class TKTestCase: XCTestCase {
  
  static let model = TripKit.loadModel()

  var tripKitContext: NSManagedObjectContext!
  
  override func setUp() {
    super.setUp()
    
    // TripKit context
    let model = TKTestCase.model!
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
  
  func request(fromFilename filename: String) throws -> TripRequest {
    let data = try self.dataFromJSON(named: filename)
    let response = try JSONDecoder().decode(TKAPI.RoutingResponse.self, from: data)
    return try TKRoutingParser.addBlocking(response, into: tripKitContext)
  }

  func trip(fromFilename filename: String, serviceFilename: String? = nil) throws -> Trip {
    let trip = try request(fromFilename: filename).tripGroups.first!.visibleTrip!

    if let serviceFilename = serviceFilename {
      for segment in trip.segments {
        if let service = segment.service {
          let data = try self.dataFromJSON(named: serviceFilename)
          let response = try JSONDecoder().decode(TKAPI.ServiceResponse.self, from: data)
          TKBuzzInfoProvider.addContent(from: response, to: service)
          break
        }
      }
    }
    return trip
  }
  
  func testThatEnvironmentWorks() {
    XCTAssertNotNil(tripKitContext)
    XCTAssertNotNil(tripKitContext.persistentStoreCoordinator)
  }
}
