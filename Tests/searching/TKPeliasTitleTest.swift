//
//  TKPeliasTitleTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit

class TKPeliasTitleTest: XCTestCase {
        
  func testAussieSubtitles() throws {
    let decoder = JSONDecoder()
    let data = try self.dataFromJSON(named: "pelias-au")
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    let coordinates = collection.toNamedCoordinates()
    
    let subtitles = coordinates.compactMap { $0.subtitle }
    XCTAssertFalse(subtitles.contains("10 Spring Street, Australia"), "Results has subtitle with just country in it.")
    
    XCTAssertNotEqual(subtitles.count, 0, "No subtitles!")
    XCTAssertEqual(Set(subtitles).count, coordinates.count, "Some subtitles repeat")
  }
  
  func testGermanSubtitles() throws {
    let decoder = JSONDecoder()
    let data = try self.dataFromJSON(named: "pelias-de")
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    let coordinates = collection.toNamedCoordinates()
    
    let subtitles = coordinates.compactMap { $0.subtitle }
    XCTAssertFalse(subtitles.contains("Kasperackerweg 31, Nürnberg, Germany"), "Result has subtitle without postcode.")
    
    XCTAssertNotEqual(subtitles.count, 0, "No subtitles!")
    XCTAssertEqual(Set(subtitles).count, 1, "Expecting one common subtitle, the city, as titles cover street names already.")
  }
  
  func testMericanSubtitles() throws {
    let decoder = JSONDecoder()
    let data = try self.dataFromJSON(named: "pelias-us")
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    let coordinates = collection.toNamedCoordinates()
    
    let subtitles = coordinates.compactMap { $0.subtitle }
    XCTAssertNotEqual(subtitles.count, 0, "No subtitles!")
    XCTAssertEqual(Set(subtitles).count, 3, "Expecting one common subtitle, different variations of the city, as titles cover street names already.")
  }
  
}
