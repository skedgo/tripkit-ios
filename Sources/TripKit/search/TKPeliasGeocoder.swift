//
//  TKPeliasGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12.09.17.
//

#if canImport(MapKit)

import Foundation
import MapKit

@available(*, unavailable, renamed: "TKPeliasGeocoder")
public typealias TKMapZenGeocoder = TKPeliasGeocoder

/// An autocompleter and geocoder powered by a Pelias backend
///
/// Implements ``TKAutocompleting``, providing instances of ``TKNamedCoordinate`` in
/// ``TKAutocompletionResult/object``. It also implements ``TKGeocoding``, returning
/// also a list of ``TKNamedCoordinate``.
///
/// This geocoder hits the Pelias instance hosted by SkedGo at `https://pelias.tripgo.com`.
public class TKPeliasGeocoder: NSObject {
  
  public override init() {
    super.init()
  }
  
  private lazy var session: URLSession = {
    var configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 5
    return URLSession(configuration: configuration)
  }()
  
  private func hitSearch(_ components: URLComponents?, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    
    guard let url = components?.url else {
      assertionFailure("Couldn't construct Pelias query URL. Check the code.")
      completion(.success([]))
      return
    }
    
    var request = URLRequest(url: url)
    request.addValue(TKServer.shared.apiKey, forHTTPHeaderField: "X-TripGo-Key")
    
    let requestID = UUID()
    TKLog.log("TKPeliasGeocoder", request: request, uuid: requestID)
    
    let dataTask = session.dataTask(with: request) { data, response, error in
      TKLog.log("TKPeliasGeocoder", response: response, data: data, orError: error as NSError?, for: request, uuid: requestID)
      
      if let error = error {
        completion(.failure(error))
      } else if let data = data {
        let result = Result { try TKPeliasGeocoder.parse(data: data) }
        completion(result)
      } else {
        assertionFailure("No data nor error received.")
        completion(.success([]))
      }
    }
    dataTask.resume()
  }
  
  private static func parse(data: Data) throws -> [TKNamedCoordinate] {
    // Useful for debugging: po JSONSerialization.jsonObject(with: data, options: .allowFragments) OR po String(data: data, encoding: .utf8)
    let decoder = JSONDecoder()
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    return collection.toNamedCoordinates()
  }
  
}

extension TKPeliasGeocoder: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKNamedCoordinate], Error>) -> Void) {
    
    guard !input.isEmpty else {
      completion(.success([]))
      return
    }
    
    let region = MKCoordinateRegion(mapRect)
    var components = URLComponents(string: "https://pelias.tripgo.com/v1/search")
    components?.queryItems = [
      URLQueryItem(name: "text", value: input),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
    ]
    
    hitSearch(components) { result in
      completion(result.map { coordinates in
        coordinates.forEach {
          $0.sortScore = $0.score(searchTerm: input, near: region).score
        }
        return TKGeocoderHelper.mergedAndPruned(coordinates, withMaximum: 10)
      })
    }
  }
  
}

extension TKPeliasGeocoder: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect, completion: @escaping (Result<[TKAutocompletionResult], Error>) -> Void) {

    guard !input.isEmpty else {
      completion(.success([]))
      return
    }

    let region = MKCoordinateRegion(mapRect)
    var components = URLComponents(string: "https://pelias.tripgo.com/v1/autocomplete")
    components?.queryItems = [
      URLQueryItem(name: "text", value: input),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
    ]
    
    hitSearch(components) { result in
      completion(result.map { coordinates in
        // Pelias likes coming back with similar locations near each
        // other, so we cluster them.
        let clusters = TKAnnotationClusterer.cluster(coordinates)
        let unique = clusters.compactMap(TKNamedCoordinate.namedCoordinate(for:))
        let pruned = TKGeocoderHelper.mergedAndPruned(unique, withMaximum: 7)
        return pruned.map {
          let score = $0.score(searchTerm: input, near: region)
          var result = TKAutocompletionResult(from: $0)
          result.score = score.score
          result.titleHighlightRanges = score.titleHighlight
          result.subtitleHighlightRanges = score.subtitleHighlight
          return result
        }
      })
    }
  }
  
  public func annotation(for result: TKAutocompletionResult, completion: @escaping (Result<MKAnnotation?, Error>) -> Void) {
    guard let coordinate = result.object as? TKNamedCoordinate else { preconditionFailure() }
    completion(.success(coordinate))
  }
  
}

extension MKAnnotation {
  
  func score(searchTerm: String, near region: MKCoordinateRegion) -> TKAutocompletionResult.ScoreHighlights {
    TKGeocodingResultScorer.calculateScore(for: self, searchTerm: searchTerm, near: region, allowLongDistance: false, minimum: 10, maximum: 60)
  }
  
}

extension TKAutocompletionResult {
  
  fileprivate init(from coordinate: TKNamedCoordinate) {
    self.init(
      object: coordinate,
      title: coordinate.title ?? Loc.Location,
      subtitle: coordinate.subtitle,
      image: TKAutocompletionResult.image(for: .pin),
      isInSupportedRegion: TKRegionManager.shared.coordinateIsPartOfAnyRegion(coordinate.coordinate)
    )
  }

}

#endif
