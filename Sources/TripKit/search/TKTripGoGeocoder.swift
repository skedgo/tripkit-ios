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

/// An autocompleter and geocoder for transport-related POIs in supported TripGo regions
///
/// Implements ``TKAutocompleting``, providing instances of ``TKNamedCoordinate`` in
/// ``TKAutocompletionResult/object``. It also implements ``TKGeocoding``, returning
/// also a list of ``TKNamedCoordinate``. These search results can be of the subclass
/// ``TKStopCoordinate`` for public transport stops matching the search.
///
/// This geocoder is a wrapper around the [`geocode.json` endpoint](https://developer.tripgo.com/specs/#tag/Geocode/paths/~1geocode.json/get) of the TripGo API.
public class TKTripGoGeocoder: NSObject {
  private var lastRect: MKMapRect = .null
  private var resultCache = NSCache<NSString, NSArray>()
  
  private var onCompletion: (String, (Result<[TKAutocompletionResult], Error>) -> Void)? = nil
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
    
    // Putting it into a local variable so that we can cancel this.
    self.onCompletion = (input, completion)
    
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
            let tuple = Self.score(named, query: input)
            if let stop = named as? TKStopCoordinate {
              return TKAutocompletionResult(
                object: named,
                title: name,
                titleHighlightRanges: tuple.titleHighlight,
                subtitle: stop.stopCode.contains(input) ? (stop.stopCode + " - " + (stop.services ?? "")) : stop.services,
                subtitleHighlightRanges: tuple.subtitleHighlight,
                image: TKModeImageFactory.shared.image(for: stop.stopModeInfo) ?? TKAutocompletionResult.image(for: .pin),
                accessoryButtonImage: TKStyleManager.image(named: "icon-search-timetable"),
                accessoryAccessibilityLabel: Loc.ShowTimetable,
                score: tuple.score
              )
            } else {
              return TKAutocompletionResult(
                object: named,
                title: name,
                titleHighlightRanges: tuple.titleHighlight,
                subtitle: named.address,
                subtitleHighlightRanges: tuple.subtitleHighlight,
                image: TKAutocompletionResult.image(for: .pin),
                score: tuple.score
              )
            }
          }
          
          if !results.isEmpty {
            self.resultCache.setObject(results as NSArray, forKey: input as NSString)
          }
          return results
        }
      )
    }
  }
  
  public func cancelAutocompletion() {
    self.onCompletion = nil
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
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
    named.sortScore = score(named, query: query).score
  }
  
  private static func score(_ named: TKNamedCoordinate, query: String? = nil) -> TKAutocompletionResult.ScoreHighlights {
    if let stop = named as? TKStopCoordinate {
      let popularity = stop.stopSortScore ?? 0
      let maxScore = 1_000
      let adjusted = min(popularity, maxScore) / (maxScore / 100)
      var ranged = TKAutocompletionResult.rangedScore(for: adjusted, min: 50, max: 80)
      if popularity > maxScore {
        let moreThanMax = popularity / maxScore
        ranged += TKAutocompletionResult.rangedScore(for: moreThanMax, min: 0, max: 10)
      }
      let highlight = query.map {
        TKAutocompletionResult.nameScore(searchTerm: $0, candidate: stop.title ?? "").ranges
      }
      return .init(score: ranged, titleHighlight: highlight ?? [])
    
    } else if let query = query, let name = named.name ?? named.title {
      let titleScore = TKAutocompletionResult.nameScore(searchTerm: query, candidate: name)
      let ranged = TKAutocompletionResult.rangedScore(for: titleScore.score, min: 0, max: 50)
      return .init(score: ranged, titleHighlight: titleScore.ranges)

    } else {
      assertionFailure("Unexpected geocoder result: \(named)")
      return .init(score: 0)
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
