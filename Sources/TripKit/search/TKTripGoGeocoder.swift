//
//  TKTripGoGeocoder.swift
//  TripKit
//
//  Created by Adrian Schönig on 13/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

@available(*, unavailable, renamed: "TKTripGoGeocoder")
public typealias TKSkedGoGeocoder = TKTripGoGeocoder

public class TKTripGoGeocoder: NSObject {
  private var lastRect: MKMapRect = .null
  private var resultCache = NSCache<NSString, NSArray>()
}

extension TKTripGoGeocoder: TKGeocoding {
  public func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    var paras: [String: Any] = [
      "q": input,
      "allowGoogle": false,
      "allowYelp": false,
    ]
    
    let coordinateRegion: MKCoordinateRegion?
    if !mapRect.isNull || !MKMapRectEqualToRect(mapRect, .world) {
      let region = MKCoordinateRegion(mapRect)
      paras["near"] = region.center.isValid ? "\(region.center.latitude),\(region.center.longitude)" : nil
      coordinateRegion = region
    } else {
      coordinateRegion = nil
    }
    
    TKRegionManager.shared.requireRegions { result in
      if case .failure(let error) = result {
        TKLog.info("Error fetching regions: \(error)")
        completion(.failure(error))
        return
      }
      
      let region = coordinateRegion.flatMap(TKRegionManager.shared.region)
      TKServer.shared.hit(TKAPI.GeocodeResponse.self, path: "geocode.json", parameters: paras, region: region) { _, _, result in
        completion(
          result.map { response in
            let coordinates = response.choices.map(\.named)
            coordinates.forEach { Self.assignScore(to: $0, query: input) }
            return coordinates
          }
        )
      }
    }
  }
}

extension TKTripGoGeocoder: TKAutocompleting {
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {
    guard !input.isEmpty else {
      completion(.success([]))
      return
    }
    
    if lastRect.isNull || !lastRect.contains(mapRect) {
      // invalidate the cache
      resultCache.removeAllObjects()
      lastRect = mapRect
    } else {
      if let cached = resultCache.object(forKey: input as NSString) as? [TKAutocompletionResult] {
        completion(.success(cached))
        return
      }
    }
    
    var paras: [String: Any] = [
      "q": input,
      "a": true
    ]
    
    let coordinateRegion = MKCoordinateRegion(mapRect)
    paras["near"] = coordinateRegion.center.isValid ? "\(coordinateRegion.center.latitude),\(coordinateRegion.center.longitude)" : nil
    
    let region = TKRegionManager.shared.region(containing: coordinateRegion)
    TKServer.shared.hit(TKAPI.GeocodeResponse.self, path: "geocode.json", parameters: paras, region: region) { [weak self] _, _, result in
      guard let self = self else { return }
      
      completion(
        result.map { response in
          let coordinates = response.choices.map(\.named)
          let results = coordinates.compactMap { named -> TKAutocompletionResult? in
            guard let name = named.name else { return nil }
            let result = TKAutocompletionResult()
            result.object = named
            result.title = name
            result.isInSupportedRegion = NSNumber(value: true)
            result.score = Self.score(named, query: input) ?? 0
            
            if let stop = named as? TKStopCoordinate {
              result.accessoryButtonImage = TKStyleManager.imageNamed("icon-search-timetable")
              result.image = TKModeImageFactory.shared.image(for: stop.stopModeInfo) ?? TKAutocompletionResult.image(forType: .pin)
              if stop.stopCode.contains(input) {
                result.subtitle = stop.stopCode + " - " + (stop.services ?? "")
              } else {
                result.subtitle = stop.services
              }
            } else {
              result.subtitle = named.address
              result.image = TKAutocompletionResult.image(forType: .pin)
            }
            
            return result
          }
          
          if !results.isEmpty {
            self.resultCache.setObject(results as NSArray, forKey: input as NSString)
          }
          return results
        }
      )
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation, Error>) -> Void) {
    guard let named = result.object as? TKNamedCoordinate else {
      assertionFailure()
      return completion(.failure(NSError(code: 97813, message: "Internal error")))
    }
    
    completion(.success(named))
  }
}

// MARK: - Preparing results

extension TKTripGoGeocoder {
  private static func assignScore(to named: TKNamedCoordinate, query: String? = nil) {
    named.sortScore = score(named, query: query) ?? 0
  }
  
  private static func score(_ named: TKNamedCoordinate, query: String? = nil) -> Int? {
    if let stop = named as? TKStopCoordinate {
      let popularity = stop.stopSortScore ?? 0
      let maxScore = 1_000
      let adjusted = min(popularity, maxScore) / (maxScore / 100)
      var ranged = TKAutocompletionResult.rangedScore(forScore: UInt(adjusted), betweenMinimum: 50, andMaximum: 80)
      if popularity > maxScore {
        let moreThanMax = adjusted / maxScore
        ranged += TKAutocompletionResult.rangedScore(forScore: UInt(moreThanMax), betweenMinimum: 0, andMaximum: 10)
      }
      return Int(ranged)
    
    } else if let query = query, let name = named.name ?? named.title {
      let titleScore = TKAutocompletionResult.scoreBased(onNameMatchBetweenSearchTerm: query, candidate: name)
      let ranged = TKAutocompletionResult.rangedScore(forScore: titleScore, betweenMinimum: 0, andMaximum: 50)
      return Int(ranged)

    } else {
      assertionFailure("Unexpected geocoder result: \(named)")
      return nil
    }
  }
}

extension TKAPI.GeocodeChoice {
  fileprivate var named: TKNamedCoordinate {
    switch self {
    case .location(let named): return named
    case .stop(let stop): return stop
    }
  }
}
