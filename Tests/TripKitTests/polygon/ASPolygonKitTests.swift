//
//  ASPolygonKitTests.swift
//  ASPolygonKitExampleTests
//
//  Created by Adrian Schoenig on 18/2/17.
//  Copyright © 2017 Adrian Schönig. All rights reserved.
//

import XCTest

import MapKit

@testable import TripKit

class ASPolygonKitTests: XCTestCase {
    
  func testAll() throws {
    let polygons = try polygonsFromJSON(named: "polygons-tripgo-170217")
    XCTAssertEqual(154, polygons.count)
  }

  func testCH() throws {
    let polygons = try polygonsFromJSON(named: "polygons-ch-170224")
    XCTAssertEqual(5, polygons.count)
    
    let merged = MKPolygon.union(polygons)
    XCTAssertEqual(1, merged.count)
  }
  
  func testUK() throws {
    let polygons = try polygonsFromJSON(named: "polygons-uk-170217")
    XCTAssertEqual(19, polygons.count)
    
    let merged = MKPolygon.union(polygons)
    XCTAssertEqual(1, merged.count)
  }

  func testScandinavia() throws {
    let polygons = try polygonsFromJSON(named: "polygons-scandinavia-170217")
    XCTAssertEqual(16, polygons.count)
    
    let merged = MKPolygon.union(polygons)
    XCTAssertEqual(1, merged.count)
  }
  
  func testInvariantToShuffling() throws {
    let polygons = try polygonsFromJSON(named: "polygons-uk-170217")
    XCTAssertEqual(19, polygons.count)
    
    let _ = (1...100).map { _ in
      let shuffled = polygons.shuffle()
      let merged = MKPolygon.union(shuffled)
      XCTAssertEqual(1, merged.count)
    }
  }
  
  func testOCFailure() throws {
    var grower = Polygon(pairs: [ (4,0), (4,3), (1,3), (1,0) ])
    let addition = Polygon(pairs: [ (5,1), (5,4), (3,4), (3,2), (2,2), (2,4), (0,4), (0,1) ])
    
    try grower.union(addition)
    XCTAssertEqual(12, grower.points.count)
  }
  
  func testSinglePointFailure() throws {
    var grower = Polygon(pairs: [ (53.5,-7.77), (52.15,-6.25), (51.2,-10) ])
    let addition = Polygon(pairs: [ (53.4600,-7.77), (54,-10), (55,-7.77) ])
    
    try grower.union(addition)
    XCTAssert(grower.points.count > 1)
  }
  
  func testPolygonContains() {
    let addition = Polygon(pairs: [ (53.4600,-7.77), (54,-10), (55,-7.77) ])
    
    XCTAssert( addition.contains(Point(ll: (53.5,-7.77)), onLine: true))
    XCTAssert(!addition.contains(Point(ll: (53.5,-7.77)), onLine: false))
  }

  func testUnsuccessfulUnion() throws {
    var grower = Polygon(pairs: [ (60.0000,-5.0000), (60.0000,0.0000), (56.2000,0.0000), (56.2000,-5.0000) ] )
    let addition = Polygon(pairs: [ (56.2500,-5.0000), (56.2500,0.0000), (55.9500,-1.8500), (55.1700,-5.7700) ] )
    
    try grower.union(addition)
    XCTAssert(grower.points.count > 1)
  }

}


extension ASPolygonKitTests {
  
  func polygonsFromJSON(named name: String) throws -> [MKPolygon] {
    guard
      let dict = try contentFromJSON(named: name) as? [String: Any],
      let encodedPolygons = dict ["polygons"] as? [String]
      else { preconditionFailure() }
    
    return encodedPolygons.map { MKPolygon(encoded: $0) }
  }
  
  func contentFromJSON(named name: String) throws -> Any {
    let jsonPath: URL
    #if SWIFT_PACKAGE
    let thisSourceFile = URL(fileURLWithPath: #file)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    jsonPath = thisDirectory
      .appendingPathComponent("data", isDirectory: true)
      .appendingPathComponent(name).appendingPathExtension("json")
    
    #else
    let bundle = Bundle(for: ASPolygonKitTests.self)
    let filePath = bundle.path(forResource: name, ofType: "json")
    jsonPath = URL(fileURLWithPath: filePath!)
    #endif

    let data = try Data(contentsOf: jsonPath)
    return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
  }
  
}

extension Collection {
  /// Return a copy of `self` with its elements shuffled
  func shuffle() -> [Iterator.Element] {
    var list = Array(self)
    list.shuffleInPlace()
    return list
  }
}

extension MutableCollection where Index == Int {
  /// Shuffle the elements of `self` in-place.
  mutating func shuffleInPlace() {

    // empty and single-element collections don't shuffle
    if count < 2 { return }
    
    for i in 0..<count - 1 {
      let j = Int(arc4random_uniform(UInt32(count - i))) + i
      guard i != j else { continue }
      swapAt(i, j)
    }
  }
}



extension MKPolygon {
  
  convenience init(encoded: String) {
    let coordinates = CLLocationCoordinate2D.decodePolyline(encoded)
    self.init(coordinates: coordinates, count: coordinates.count)
  }
  
}

#if os(iOS)

extension MKPolygon : CustomPlaygroundDisplayConvertible {
  public var playgroundDescription: Any {
    return quickLookImage ?? description
  }
  
  fileprivate var quickLookImage: UIImage? {
    let options = MKMapSnapshotter.Options()
    options.mapRect = self.boundingMapRect
    
    let snapshotter = MKMapSnapshotter(options: options)
    var image: UIImage?
    
    let semaphore = DispatchSemaphore(value: 1)
    snapshotter.start() { snapshot, error in
      
      image = snapshot?.image
      semaphore.signal()
      
    }
    
    semaphore.wait()

    return image
  }
  
  public var debugQuickLookObject: Any {
    return quickLookImage ?? description
  }

}

#endif
