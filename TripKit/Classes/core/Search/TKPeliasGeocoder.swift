//
//  TKPeliasGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12.09.17.
//

import Foundation
import MapKit

public class TKPeliasGeocoder: NSObject {
  
  public override init() {
    super.init()
  }
  
  private enum Result {
    case success([SGKNamedCoordinate])
    case failure(Error?)
  }
  
  private func hitSearch(_ components: URLComponents?, completion: @escaping (Result) -> Void) {
    
    guard let url = components?.url else {
      assertionFailure("Couldn't construct MapZen query URL. Check the code.")
      return
    }
    
    var request = URLRequest(url: url)
    request.addValue(SVKServer.shared.apiKey, forHTTPHeaderField: "X-TripGo-Key")
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      
      if let data = data {
        do {
          let coordinates = try TKPeliasGeocoder.parse(data: data)
          completion(.success(coordinates))
        } catch {
          completion(.failure(error))
        }
      } else {
        completion(.failure(error))
      }
    }
    task.resume()
  }
  
  private static func parse(data: Data) throws -> [SGKNamedCoordinate] {
    // Useful for debugging: po JSONSerialization.jsonObject(with: data, options: .allowFragments) OR po String(data: data, encoding: .utf8)
    let decoder = JSONDecoder()
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    return collection.toNamedCoordinates()
  }
  
}

extension TKPeliasGeocoder: SGGeocoder {
  
  public func geocodeString(_ inputString: String, nearRegion mapRect: MKMapRect, success: @escaping SGGeocoderSuccessBlock, failure: SGGeocoderFailureBlock? = nil) {
    
    guard !inputString.isEmpty else {
      success(inputString, [])
      return
    }
    
    let region = MKCoordinateRegionForMapRect(mapRect)
    var components = URLComponents(string: "https://pelias.tripgo.com/v1/search")
    components?.queryItems = [
      URLQueryItem(name: "text", value: inputString),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
    ]
    
    hitSearch(components) { result in
      switch result {
      case .success(let coordinates):
        coordinates.forEach { $0.setScore(searchTerm: inputString, near: region) }
        let pruned = SGBaseGeocoder.mergedAndPruned(coordinates, withMaximum: 10)
        success(inputString, pruned)
      case .failure(let error):
        failure?(inputString, error)
      }
    }
  }
  
}

extension TKPeliasGeocoder: SGAutocompletionDataProvider {
  
  public func autocompleteSlowly(_ string: String, for mapRect: MKMapRect, completion: @escaping SGAutocompletionDataResultBlock) {
    
    guard !string.isEmpty else {
      completion([])
      return
    }

    let region = MKCoordinateRegionForMapRect(mapRect)
    var components = URLComponents(string: "https://pelias.tripgo.com/v1/autocomplete")
    components?.queryItems = [
      URLQueryItem(name: "text", value: string),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
    ]
    
    hitSearch(components) { result in
      switch result {
      case .success(let coordinates):
        coordinates.forEach { $0.setScore(searchTerm: string, near: region) }
        
        // MapZen likes coming back with similar locations near each
        // other, so we cluster them.
        let clusters = TKAnnotationClusterer.cluster(coordinates)
        let unique = clusters.flatMap(SGKNamedCoordinate.namedCoordinate(for:))
        
        let pruned = SGBaseGeocoder.mergedAndPruned(unique, withMaximum: 7)
        completion(pruned.map(SGAutocompletionResult.init))
      case .failure(_):
        completion(nil)
      }
    }
  }
  
  public func annotation(for result: SGAutocompletionResult) -> MKAnnotation? {
    return result.object as? SGKNamedCoordinate
  }
  
}

extension SGKNamedCoordinate {
  
  fileprivate func setScore(searchTerm: String, near region: MKCoordinateRegion) {
    self.sortScore = Int(TKGeocodingResultScorer.calculateScore(for: self, searchTerm: searchTerm, near: region, allowLongDistance: false, minimum: 10, maximum: 60))
  }
  
}

extension SGAutocompletionResult {
  
  fileprivate convenience init(from coordinate: SGKNamedCoordinate) {
    self.init()
    
    title = coordinate.title ?? Loc.Location
    subtitle = coordinate.subtitle
    object = coordinate
    score = coordinate.sortScore
    image = SGAutocompletionResult.image(forType: .pin)
    isInSupportedRegion = NSNumber(value: TKRegionManager.shared.coordinateIsPartOfAnyRegion(coordinate.coordinate))
  }

}
