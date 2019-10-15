//
//  TKPeliasGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12.09.17.
//

import Foundation
import MapKit

import RxSwift

@available(*, unavailable, renamed: "TKPeliasGeocoder")
public typealias TKMapZenGeocoder = TKPeliasGeocoder

public class TKPeliasGeocoder: NSObject {
  
  public override init() {
    super.init()
  }
  
  private enum Result {
    case success([TKNamedCoordinate])
    case failure(Error?)
  }
  
  private func hitSearch(_ components: URLComponents?) -> Single<[TKNamedCoordinate]> {
    
    guard let url = components?.url else {
      assertionFailure("Couldn't construct MapZen query URL. Check the code.")
      return .just([])
    }
    
    var request = URLRequest(url: url)
    request.addValue(TKServer.shared.apiKey, forHTTPHeaderField: "X-TripGo-Key")
    
    return URLSession.shared.rx.data(request: request)
      .map { data in
        return try TKPeliasGeocoder.parse(data: data)
      }
      .asSingle()
  }
  
  private static func parse(data: Data) throws -> [TKNamedCoordinate] {
    // Useful for debugging: po JSONSerialization.jsonObject(with: data, options: .allowFragments) OR po String(data: data, encoding: .utf8)
    let decoder = JSONDecoder()
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    return collection.toNamedCoordinates()
  }
  
}

extension TKPeliasGeocoder: TKGeocoding {
  
  public func geocode(_ input: String, near mapRect: MKMapRect) -> Single<[TKNamedCoordinate]> {
    
    guard !input.isEmpty else {
      return .just([])
    }
    
    let region = MKCoordinateRegion(mapRect)
    var components = URLComponents(string: "https://pelias.tripgo.com/v1/search")
    components?.queryItems = [
      URLQueryItem(name: "text", value: input),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
    ]
    
    return hitSearch(components)
      .map { coordinates in
        coordinates.forEach { $0.setScore(searchTerm: input, near: region) }
        return TKGeocoderHelper.mergedAndPruned(coordinates, withMaximum: 10)
      }
  }
  
}

extension TKPeliasGeocoder: TKAutocompleting {
  
  public func autocomplete(_ input: String, near mapRect: MKMapRect) -> Single<[TKAutocompletionResult]> {

    guard !input.isEmpty else {
      return .just([])
    }

    let region = MKCoordinateRegion(mapRect)
    var components = URLComponents(string: "https://pelias.tripgo.com/v1/autocomplete")
    components?.queryItems = [
      URLQueryItem(name: "text", value: input),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
    ]
    
    return hitSearch(components)
      .map { coordinates in
        coordinates.forEach { $0.setScore(searchTerm: input, near: region) }
        
        // Pelias likes coming back with similar locations near each
        // other, so we cluster them.
        let clusters = TKAnnotationClusterer.cluster(coordinates)
        let unique = clusters.compactMap(TKNamedCoordinate.namedCoordinate(for:))
        let pruned = TKGeocoderHelper.mergedAndPruned(unique, withMaximum: 7)
        return pruned.map(TKAutocompletionResult.init)
      }
  }
  
  public func annotation(for result: TKAutocompletionResult) -> Single<MKAnnotation> {
    guard let coordinate = result.object as? TKNamedCoordinate else { preconditionFailure() }
    return .just(coordinate)
  }
  
}

extension TKNamedCoordinate {
  
  func setScore(searchTerm: String, near region: MKCoordinateRegion) {
    self.sortScore = Int(TKGeocodingResultScorer.calculateScore(for: self, searchTerm: searchTerm, near: region, allowLongDistance: false, minimum: 10, maximum: 60))
  }
  
}

extension TKAutocompletionResult {
  
  fileprivate convenience init(from coordinate: TKNamedCoordinate) {
    self.init()
    
    title = coordinate.title ?? Loc.Location
    subtitle = coordinate.subtitle
    object = coordinate
    score = coordinate.sortScore
    image = TKAutocompletionResult.image(forType: .pin)
    isInSupportedRegion = NSNumber(value: TKRegionManager.shared.coordinateIsPartOfAnyRegion(coordinate.coordinate))
  }

}
