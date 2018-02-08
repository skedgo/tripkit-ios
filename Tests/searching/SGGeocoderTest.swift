//
//  SGAutocompletionTest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 24/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import XCTest
import MapKit

@testable import TripKit

class SGGeocoderTest: XCTestCase {
  var geocoder: SGAggregateGeocoder!
  
  // sample regions for testing
  let sydney = MKCoordinateRegion.region(latitude: -33.861412, longitude: 151.210774)
  let newYork = MKCoordinateRegion.region(latitude: 40.716688, longitude: -74.006138)
  
  override func setUp() {
    geocoder = aggregateGeocoder()
  }
  
  //MARK: - The Tests
  
  func testBrandonAveSydney() {
    geocoderPasses(geocoder, input: "Brandon Ave, Sydney", near: sydney, resultsInAny: ["Brandon Ave", "Brandon Avenue"], noneOf: ["Gordon Ave", "Brothel"])

    // We want no garbage matches from Foursquare
    let another = aggregateGeocoder()
    geocoderPasses(another, input: "Brandon Ave", near: sydney, noneOf: ["Gordon Ave", "Brothel"])
}
  
  func testNoUnnecessaryStreetNumbers() {
    // We want no garbage matches from Foursquare
    geocoderPasses(geocoder, input: "George St, Sydney", near: sydney, resultsInAny: ["George Street"], noneOf: ["Tesla Loading Dock", "333 George", "345 George", "261 George"])
  }
  
  func testGeorgeSt2554() {
    // We want to result first which starts with a house number
    geocoderPasses(geocoder, input: "George St", near: sydney, bestStartsWithAny: ["George St"])
  }

  func testGilbertPark4240() {
    geocoderPasses(geocoder, input: "Gilbert Park, Manly", near: sydney, resultsInAny: ["Gilbert Park"])
  }

  func testGarrisSt4252() {
    geocoderPasses(geocoder, input: "608 Harris", near: sydney, resultsInAny: ["608 Harris St"])
  }

  func testDeeWhy5147() {
    geocoderPasses(geocoder, input: "Dee Why", near: sydney, bestStartsWithAny: ["Dee Why"])
  }

  func testMOMA6279() {
    geocoderPasses(geocoder, input: "MoMA", near: newYork, resultsInAny: ["Museum of Modern Art", "MOMA"])
    
    let second = aggregateGeocoder()
    geocoderPasses(second, input: "Museum of Modern Art", near: newYork, resultsInAny: ["Museum of Modern Art", "MOMA"])

    // Shouldn't just find it but also rank it first
    let third = aggregateGeocoder()
    geocoderPasses(third, input: "moma", near: newYork, bestStartsWithAny: ["Museum of Modern Art", "The Museom of Modern Art", "MoMA"])
  }
  
  func testRPATypo6294() {
    // We want no garbage matches from Foursquare
    geocoderPasses(geocoder, input: "RPA Emergancy", near: sydney, noneOf: ["Callan Park"])
  }
  
  
  func testExploreAutocomplete7336() {
    // We want no garbage matches from Foursquare
    geocoderPasses(geocoder, input: "Lend Lease Darling Quarter Theatre", near: sydney, resultsInAny: ["Darling Quarter Theatre", "lend lease Darling Quarter"])
  }

  func testWrongSydneyAirport7838() {
    // We want no garbage matches from Foursquare
    let SYD = CLLocationCoordinate2D(latitude: -33.939932, longitude: 151.175212)
    geocoderPasses(geocoder, input: "Sydney International Airport", near: sydney, of: SYD)
  }
  
  //MARK: - Private helpers
  
  fileprivate func aggregateGeocoder() -> SGAggregateGeocoder {
    var geocoders: [SGGeocoder] = [SGAppleGeocoder()]
    
    let env = ProcessInfo.processInfo.environment
    if let apiKey = env["TRIPGO_API_KEY"], !apiKey.isEmpty {
      TripKit.apiKey = apiKey
      geocoders.append(SGBuzzGeocoder())
    } else {
      XCTFail("Could not construct SGBuzzGeocoder. Check environment variables.")
    }
    
    if let clientID = env["FOURSQUARE_CLIENT_ID"], !clientID.isEmpty,
       let clientSecret = env["FOURSQUARE_CLIENT_SECRET"], !clientSecret.isEmpty {
      let foursquare = SGFoursquareGeocoder(
        clientID: clientID,
        clientSecret: clientSecret
      )
      geocoders.append(foursquare)
    } else {
      XCTFail("Could not construct Foursquare geocoder. Check environment variables.")
    }

    if let apiKey = env["MAPZEN_API_KEY"], !apiKey.isEmpty {
      let mapZen = TKMapZenGeocoder(apiKey: apiKey)
      geocoders.append(mapZen)
    } else {
      XCTFail("Could not construct MapZen geocoder. Check environment variables.")
    }
    
    return SGAggregateGeocoder(geocoders: geocoders)
  }
  
  fileprivate func geocoderPasses(
    _ geocoder: SGGeocoder,
    input: String,
    near region: MKCoordinateRegion,
    resultsInAny any: [String] = [],
    noneOf none: [String] = [],
    of coordinate: CLLocationCoordinate2D? = nil)
  {
    let expectation = self.expectation(description: "expectation-\(input)")
    
    geocoder.passes(input, near:region, resultsInAny:any, noneOf:none, of:coordinate) { passed in
      XCTAssertNil(passed)
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 15) { error in
      XCTAssertNil(error)
    }
  }
  
  fileprivate func geocoderPasses(
    _ geocoder: SGGeocoder,
    input: String,
    near region: MKCoordinateRegion,
    bestStartsWithAny starts: [String])
  {
    let expectation = self.expectation(description: "expectation-\(input)")
    
    geocoder.passes(input, near:region, bestStartsWithAny: starts) { passed in
      XCTAssertNil(passed)
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 15) { error in
      XCTAssertNil(error)
    }
  }
}

extension SGGeocoder {
  
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
    completion handler: @escaping (String?) -> Void)
  {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    self.geocodeString(input, nearRegion: mapRect,
      success: { query, results in
        
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
            handler("Result '\(title)' is bad as it contains '\(bad)'")
            return
          }
        }
        handler(foundGood ? nil : "Found no result containing '\(any)'")
        
      },
      failure: { query, error in
        handler("Error: \(String(describing: error))")
    })
  }
  
  /// Runs the geocoder and checks that the highest scored result starts with any of the
  /// provided strings.
  ///
  /// - parameter input: String to search for
  /// - parameter region: Region near which to search
  /// - parameter starts: Any result needs to start with any of these
  /// - parameter completion: Called when done, with one parameter indicating if all results pass
  func passes(_ input: String, near region: MKCoordinateRegion, bestStartsWithAny starts: [String], completion handler: @escaping (String?) -> Void)
  {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    self.geocodeString(
      input,
      nearRegion: mapRect,
      success: { query, results in
        
        let (_, best) = results.reduce((0, nil as SGKNamedCoordinate?)) { previous, next in
          if next.sortScore > previous.0 {
            return (next.sortScore, next)
          } else {
            return previous
          }
        }
        
        // check if we found a good result
        if let title = best?.title {
          for good in starts where title.lowercased().hasPrefix(good.lowercased()) {
            handler(nil)
            return
          }
        }
        handler("Best match '\(String(describing: best?.title))' does not have good title.")
        
    },
    failure: { query, error in
        handler("Error: \(String(describing: error))")
    })
  }
}


