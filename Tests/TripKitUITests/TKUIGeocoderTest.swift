//
//  TKUIGeocoderTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import MapKit

@testable import TripKit

class TKUIGeocoderTest: XCTestCase {
  var geocoder: TKAggregateGeocoder!
  
  // sample regions for testing
  let sydney = MKCoordinateRegion.region(latitude: -33.861412, longitude: 151.210774)
  let newYork = MKCoordinateRegion.region(latitude: 40.716688, longitude: -74.006138)
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    
    if TKServer.developmentServer != nil {
      TKServer.developmentServer = nil // make sure to hit production
    }
    
    geocoder = try aggregateGeocoder()
  }
  
  //MARK: - The Tests
  
  func testBrandonAveSydney() async throws {
    await geocoderPasses(geocoder, input: "Brandon Ave, Sydney", near: sydney, resultsInAny: ["Brandon Ave", "Brandon Avenue"], noneOf: ["Gordon Ave", "Brothel"])

    // We want no garbage matches from Foursquare
    let another = try aggregateGeocoder()
    await geocoderPasses(another, input: "Brandon Ave", near: sydney, noneOf: ["Gordon Ave", "Brothel"])
}
  
  func testNoUnnecessaryStreetNumbers() async {
    // We want no garbage matches from Foursquare
    await geocoderPasses(geocoder, input: "George St, Sydney", near: sydney, resultsInAny: ["George Street", "George St"], noneOf: ["Tesla Loading Dock", "333 George", "345 George", "261 George"])
  }

  func testGeorgeSt2554() async {
    // We want to result first which starts with a house number
    //
    await geocoderPasses(geocoder, input: "George St", near: sydney, bestStartsWithAny: ["George St"])
  }

  func testGilbertPark4240() async {
    await geocoderPasses(geocoder, input: "Gilbert Park, Manly", near: sydney, resultsInAny: ["Gilbert Park"])
  }

  func testGarrisSt4252() async {
    await geocoderPasses(geocoder, input: "608 Harris", near: sydney, resultsInAny: ["608 Harris St"])
  }

  func testDeeWhy5147() async {
    await geocoderPasses(geocoder, input: "Dee Why", near: sydney, bestStartsWithAny: ["Dee Why"])
  }

  func testMOMA6279() async throws {
    await geocoderPasses(geocoder, input: "MoMA", near: newYork, resultsInAny: ["Museum of Modern Art", "MOMA"])
    
    let second = try aggregateGeocoder()
    await geocoderPasses(second, input: "Museum of Modern Art", near: newYork, resultsInAny: ["Museum of Modern Art", "MOMA"])

    // Shouldn't just find it but also rank it first
    let third = try aggregateGeocoder()
    await geocoderPasses(third, input: "moma", near: newYork, bestStartsWithAny: ["Museum of Modern Art", "The Museom of Modern Art", "MoMA"])
  }
  
  func testRPATypo6294() async {
    // We want no garbage matches from Foursquare
    await geocoderPasses(geocoder, input: "RPA Emergancy", near: sydney, noneOf: ["Callan Park"])
  }
  
  func testExploreAutocomplete7336() async {
    // We want no garbage matches from Foursquare
    await geocoderPasses(geocoder, input: "Lend Lease Darling Quarter Theatre", near: sydney, resultsInAny: ["Darling Quarter Theatre", "lend lease Darling Quarter"])
  }

  func testWrongSydneyAirport7838() async {
    // We want no garbage matches from Foursquare
    let SYD = CLLocationCoordinate2D(latitude: -33.939932, longitude: 151.175212)
    await geocoderPasses(geocoder, input: "Sydney International Airport", near: sydney, of: SYD)
  }
  
  //MARK: - Private helpers
  
  fileprivate func aggregateGeocoder() throws -> TKAggregateGeocoder {
    var geocoders: [TKGeocoding] = [TKAppleGeocoder()]
    
    let env = ProcessInfo.processInfo.environment
    if let apiKey = env["TRIPGO_API_KEY"], !apiKey.isEmpty {
      TripKit.apiKey = apiKey
      geocoders.append(TKTripGoGeocoder())
      geocoders.append(TKPeliasGeocoder())
    } else {
      try XCTSkipIf(true, "TripGo API key missing. Check environment variable 'TRIPGO_API_KEY'.")
    }
    
    return TKAggregateGeocoder(geocoders: geocoders)
  }
}

// MARK: - Helpers

extension TKUIGeocoderTest {
  
  enum Error: Swift.Error {
    case badResult(String)
    case noGoodResult(String)
    case bestIsNoGood(String)
  }
  
  fileprivate func geocoderPasses(
    _ geocoder: TKGeocoding,
    input: String,
    near region: MKCoordinateRegion,
    resultsInAny any: [String] = [],
    noneOf none: [String] = [],
    of coordinate: CLLocationCoordinate2D? = nil,
    file: StaticString = #file,
    line: UInt = #line)
    async
  {
    await geocoder.passes(input, near: region, resultsInAny: any, noneOf: none, of: coordinate, file: file, line: line)
  }
  
  fileprivate func geocoderPasses(
    _ geocoder: TKGeocoding,
    input: String,
    near region: MKCoordinateRegion,
    bestStartsWithAny starts: [String],
    file: StaticString = #file,
    line: UInt = #line
  ) async {
    await geocoder.passes(input, near:region, bestStartsWithAny: starts, file: file, line: line)
  }
}

extension TKGeocoding {
  
  /// Runs the geocoder and checks that the results match any of the provided good results
  /// in `any` and don't match any of the provided bad results in `none`. Then calls the
  /// completion indicating if the results pass the test.
  ///
  /// - parameter input: String to search for
  /// - parameter region: Region near which to search
  /// - parameter any: Any result needs to match any of these to pass
  /// - parameter none: No result is allowed to match any of these to pass
  /// - parameter completion: Called when done, with one parameter indicating error
  func passes(
    _ input: String,
    near region: MKCoordinateRegion,
    resultsInAny any: [String] = [],
    noneOf none: [String] = [],
    of coordinate: CLLocationCoordinate2D? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) async {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    let results: [TKNamedCoordinate]
    do {
      results = try await geocode(input, near: mapRect)
    } catch {
      return XCTFail("Geocoding failed with error: \(error)", file: file, line: line)
    }
    var foundGood = any.count == 0
    for result in results {
      // ignore results without a title
      guard let title = result.title else { continue }
      
      // check if we found a good result
      for good in any where title.contains(good) {
        foundGood = true
        break
      }
      
      // none should be bad
      for bad in none where title.contains(bad) {
        XCTFail("Result '\(title)' is bad as it contains '\(bad)'", file: file, line: line)
      }
    }
    XCTAssertTrue(foundGood, "Found no result containing '\(any)'", file: file, line: line)
  }
  
  /// Runs the geocoder and checks that the highest scored result starts with any of the
  /// provided strings.
  ///
  /// - parameter input: String to search for
  /// - parameter region: Region near which to search
  /// - parameter starts: Any result needs to start with any of these
  /// - parameter completion: Called when done, with one parameter indicating if all results pass
  func passes(
    _ input: String,
    near region: MKCoordinateRegion,
    bestStartsWithAny starts: [String],
    file: StaticString = #file,
    line: UInt = #line
  ) async {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    let results: [TKNamedCoordinate]
    do {
      results = try await geocode(input, near: mapRect)
    } catch {
      return XCTFail("Geocoding failed with error: \(error)", file: file, line: line)
    }
    let (_, best) = results.reduce((0, nil as TKNamedCoordinate?)) { previous, next in
      if next.sortScore > previous.0 {
        return (next.sortScore, next)
      } else {
        return previous
      }
    }
    
    // check if we found a good result
    if let title = best?.title {
      for good in starts where title.lowercased().hasPrefix(good.lowercased()) {
        return
      }
    }
    XCTFail("Best match '\(String(describing: best?.title))' does not have good title.", file: file, line: line)
  }
}


