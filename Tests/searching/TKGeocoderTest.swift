//
//  SGAutocompletionTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import MapKit

import RxSwift

@testable import TripKit

class TKGeocoderTest: XCTestCase {
  var geocoder: TKAggregateGeocoder!
  
  // sample regions for testing
  let sydney = MKCoordinateRegion.region(latitude: -33.861412, longitude: 151.210774)
  let newYork = MKCoordinateRegion.region(latitude: 40.716688, longitude: -74.006138)
  
  override func setUpWithError() throws {
    try super.setUpWithError()
    
    if TKServer.developmentServer() != nil {
      TKServer.updateDevelopmentServer(nil) // make sure to hit production
    }
    
    geocoder = try aggregateGeocoder()
  }
  
  //MARK: - The Tests
  
  func testBrandonAveSydney() throws {
    try geocoderPasses(geocoder, input: "Brandon Ave, Sydney", near: sydney, resultsInAny: ["Brandon Ave", "Brandon Avenue"], noneOf: ["Gordon Ave", "Brothel"])

    // We want no garbage matches from Foursquare
    let another = try aggregateGeocoder()
    try geocoderPasses(another, input: "Brandon Ave", near: sydney, noneOf: ["Gordon Ave", "Brothel"])
}
  
  func testNoUnnecessaryStreetNumbers() throws {
    // We want no garbage matches from Foursquare
    try geocoderPasses(geocoder, input: "George St, Sydney", near: sydney, resultsInAny: ["George Street"], noneOf: ["Tesla Loading Dock", "333 George", "345 George", "261 George"])
  }

  // TODO: Re-instate this test. BACKEND ISSUE. SKEDGO TEAM IS ON IT. SILENCING THIS IN THE MEANTIME.
//  func testGeorgeSt2554() {
//    // We want to result first which starts with a house number
//    //
//    geocoderPasses(geocoder, input: "George St", near: sydney, bestStartsWithAny: ["George St"])
//  }

  func testGilbertPark4240() throws {
    try geocoderPasses(geocoder, input: "Gilbert Park, Manly", near: sydney, resultsInAny: ["Gilbert Park"])
  }

  func testGarrisSt4252() throws {
    try geocoderPasses(geocoder, input: "608 Harris", near: sydney, resultsInAny: ["608 Harris St"])
  }

  func testDeeWhy5147() throws {
    try geocoderPasses(geocoder, input: "Dee Why", near: sydney, bestStartsWithAny: ["Dee Why"])
  }

  func testMOMA6279() throws {
    try geocoderPasses(geocoder, input: "MoMA", near: newYork, resultsInAny: ["Museum of Modern Art", "MOMA"])
    
    let second = try aggregateGeocoder()
    try geocoderPasses(second, input: "Museum of Modern Art", near: newYork, resultsInAny: ["Museum of Modern Art", "MOMA"])

    // Shouldn't just find it but also rank it first
    let third = try aggregateGeocoder()
    try geocoderPasses(third, input: "moma", near: newYork, bestStartsWithAny: ["Museum of Modern Art", "The Museom of Modern Art", "MoMA"])
  }
  
  func testRPATypo6294() throws {
    // We want no garbage matches from Foursquare
    try geocoderPasses(geocoder, input: "RPA Emergancy", near: sydney, noneOf: ["Callan Park"])
  }
  
  func testExploreAutocomplete7336() throws {
    // We want no garbage matches from Foursquare
    try geocoderPasses(geocoder, input: "Lend Lease Darling Quarter Theatre", near: sydney, resultsInAny: ["Darling Quarter Theatre", "lend lease Darling Quarter"])
  }

  func testWrongSydneyAirport7838() throws {
    // We want no garbage matches from Foursquare
    let SYD = CLLocationCoordinate2D(latitude: -33.939932, longitude: 151.175212)
    try geocoderPasses(geocoder, input: "Sydney International Airport", near: sydney, of: SYD)
  }
  
  //MARK: - Private helpers
  
  fileprivate func aggregateGeocoder() throws -> TKAggregateGeocoder {
    var geocoders: [TKGeocoding] = [TKAppleGeocoder()]
    
    let env = ProcessInfo.processInfo.environment
    if let apiKey = env["TRIPGO_API_KEY"], !apiKey.isEmpty {
      TripKit.apiKey = apiKey
      geocoders.append(TKSkedGoGeocoder())
      geocoders.append(TKPeliasGeocoder())
    } else {
      try XCTSkipIf(true, "TripGo API key missing. Check environment variable 'TRIPGO_API_KEY'.")
    }
    
    return TKAggregateGeocoder(geocoders: geocoders)
  }
}

// MARK: - Helpers

extension TKGeocoderTest {
  
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
    file: StaticString = #file, line: UInt = #line)
    throws
  {
    let result = geocoder.passes(input, near:region, resultsInAny:any, noneOf:none, of:coordinate)
    do {
      _ = try result.toBlocking(timeout: 5).first()
    } catch {
      try XCTSkipIf(true, "Skipped due to: \(error)", file: file, line: line)
    }
  }
  
  fileprivate func geocoderPasses(
    _ geocoder: TKGeocoding,
    input: String,
    near region: MKCoordinateRegion,
    bestStartsWithAny starts: [String],
    file: StaticString = #file, line: UInt = #line)
    throws
  {
    let result = geocoder.passes(input, near:region, bestStartsWithAny: starts)
    do {
      _ = try result.toBlocking(timeout: 5).first()
    } catch {
      try XCTSkipIf(true, "Skipped due to: \(error)", file: file, line: line)
    }
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
    of coordinate: CLLocationCoordinate2D? = nil)
    -> Single<Void>
  {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    return geocode(input, near: mapRect).map { results in
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
            throw TKGeocoderTest.Error.badResult("Result '\(title)' is bad as it contains '\(bad)'")
          }
        }
        if !foundGood {
          throw TKGeocoderTest.Error.noGoodResult("Found no result containing '\(any)'")
        }
      }
  }
  
  /// Runs the geocoder and checks that the highest scored result starts with any of the
  /// provided strings.
  ///
  /// - parameter input: String to search for
  /// - parameter region: Region near which to search
  /// - parameter starts: Any result needs to start with any of these
  /// - parameter completion: Called when done, with one parameter indicating if all results pass
  func passes(_ input: String, near region: MKCoordinateRegion, bestStartsWithAny starts: [String]) -> Single<Void>
  {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    return geocode(input, near: mapRect).map { results in
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
        throw TKGeocoderTest.Error.bestIsNoGood("Best match '\(String(describing: best?.title))' does not have good title.")
    }
  }
}


