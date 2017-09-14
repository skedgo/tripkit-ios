//
//  TKMapZenGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 12.09.17.
//

import Foundation
import MapKit

public class TKMapZenGeocoder: NSObject {
  
  private let apiKey: String
  
  public init(apiKey: String) {
    self.apiKey = apiKey
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
    
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      
      if let data = data {
        do {
          let coordinates = try TKMapZenGeocoder.parse(data: data)
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
    // Useful for debugging: po JSONSerialization.jsonObject(with: data, options: .allowFragments)
    let decoder = JSONDecoder()
    let collection = try decoder.decode(TKGeoJSON.self, from: data)
    
    switch collection {
    case .collection(let features):
      return features.flatMap(SGKNamedCoordinate.init(from:))
    case .feature(let feature):
      if let coordinate = SGKNamedCoordinate(from: feature) {
        return [coordinate]
      } else {
        return []
      }
    }
  }
  
}

extension TKMapZenGeocoder: SGGeocoder {
  
  public func geocodeString(_ inputString: String, nearRegion mapRect: MKMapRect, success: @escaping SGGeocoderSuccessBlock, failure: SGGeocoderFailureBlock? = nil) {
    
    guard inputString.count > 0 else {
      success(inputString, [])
      return
    }
    
    let region = MKCoordinateRegionForMapRect(mapRect)
    var components = URLComponents(string: "https://search.mapzen.com/v1/search")
    components?.queryItems = [
      URLQueryItem(name: "text", value: inputString),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
      URLQueryItem(name: "api_key", value: apiKey),
    ]
    
    hitSearch(components) { result in
      switch result {
      case .success(let coordinates):
        coordinates.forEach { $0.setScore(searchTerm: inputString, near: region) }
        let pruned = SGBaseGeocoder.filteredMergedAndPruned(coordinates, limitedToRegion: region, withMaximum: 10)
        success(inputString, pruned)
      case .failure(let error):
        failure?(inputString, error)
      }
    }
  }
  
}

extension TKMapZenGeocoder: SGAutocompletionDataProvider {
  
  public var resultType: SGAutocompletionDataProviderResultType { return .location }
  
  public func autocompleteSlowly(_ string: String, for mapRect: MKMapRect, completion: @escaping SGAutocompletionDataResultBlock) {
    
    guard string.count > 0 else {
      completion([])
      return
    }

    let region = MKCoordinateRegionForMapRect(mapRect)
    var components = URLComponents(string: "https://search.mapzen.com/v1/autocomplete")
    components?.queryItems = [
      URLQueryItem(name: "text", value: string),
      URLQueryItem(name: "focus.point.lat", value: String(region.center.latitude)),
      URLQueryItem(name: "focus.point.lon", value: String(region.center.longitude)),
      URLQueryItem(name: "api_key", value: apiKey),
    ]
    
    hitSearch(components) { result in
      switch result {
      case .success(let coordinates):
        coordinates.forEach { $0.setScore(searchTerm: string, near: region) }
        completion(coordinates.map(SGAutocompletionResult.init))
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
  fileprivate convenience init?(from geojson: TKGeoJSON.Feature) {
    switch geojson.geometry {
    case .point(let position):
      let mapZen = geojson.properties as? TKMapZenProperties
      
      self.init(latitude: position.latitude, longitude: position.longitude, name: mapZen?.name, address: mapZen?.label)
      
    default:
      return nil
      
    }
  }
  
  fileprivate func setScore(searchTerm: String, near region: MKCoordinateRegion) {
    self.sortScore = Int(TKGeocodingResultScorer.calculateScore(for: self, searchTerm: searchTerm, near: region, allowLongDistance: false, minimum: 25, maximum: 80))
  }
  
}

extension SGAutocompletionResult {
  fileprivate convenience init(from coordinate: SGKNamedCoordinate) {
    self.init()
    
    title = coordinate.title ?? Loc.Location
    subtitle = coordinate.subtitle
    object = coordinate
    score = coordinate.sortScore
  }

}

