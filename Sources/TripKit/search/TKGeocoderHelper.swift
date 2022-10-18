//
//  TKGeocoderHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

extension TKGeocoding {
  
  @available(*, renamed: "geocode(_:near:)")
  public func geocode(_ object: TKGeocodable, near region: MKMapRect, completion: @escaping (Result<Void, Error>) -> Void) {
    Task {
      do {
        try await geocode(object, near: region)
        completion(.success(()))
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  
  public func geocode(_ object: TKGeocodable, near region: MKMapRect) async throws {
    try await TKGeocoderHelper.geocode(object, using: self, near: region)
  }
  
}

public class TKGeocoderHelper: NSObject {

  public static var preferredGeocoder: TKGeocoding = {
    return TKAppleGeocoder()
  }()
  
  private override init() {
    super.init()
  }
  
  public enum GeocodingError: Error {
    case missingAddress
    case serverFoundNoMatch(String)
    case unknownServerError(String)
  }
  
  @objc(errorForNoLocationFoundForInput:)
  public static func errorForNoLocationFound(forInput input: String) -> Error {
    let format = NSLocalizedString("'%@' not found.", tableName: "Shared", bundle: .tripKit, comment: "Error when location search for %input was not successful. (old key: RequestErrorFormat)")
    let message = String(format: format, input)
    return NSError(code: 64720, message: message)
  }
  
  @available(*, renamed: "geocode(_:using:near:)")
  public class func geocode(_ object: TKGeocodable, using geocoder: TKGeocoding, near region: MKMapRect, completion: @escaping (Result<Void, Error>) -> Void) {
    
    guard let address = object.addressForGeocoding, !address.isEmpty else {
      completion(.failure(GeocodingError.missingAddress))
      return
    }
    
    return geocoder.geocode(address, near: region) { result in
      DispatchQueue.main.async {
        switch result {
        case .failure(let error):
          completion(.failure(error))
        case .success(let results):
          guard let best = TKGeocoderHelper.pickBest(from: results) else {
            completion(.failure(GeocodingError.serverFoundNoMatch(address)))
            return
          }
          

          // The objects stored in the objectsToBeGeocoded dictionary do
          // not have coordinate values assigned (e.g., a location from
          // contact), therefore, we need to manually set them afterwards.
          // Also, as part of the method call, another reverse geocoding
          // operation is performed on an Apple geocoder. This is because
          // the coordinate from the "bestMatch" object may not match the
          // address originally stored in the "geocodableObject", hence,
          // the reverse geocoding returns the updated address matching
          // the coordinate.
          object.assign(best.coordinate, forAddress: address)
          
          completion(.success(()))
        }
      }
    }
  }
  
  public class func geocode(_ object: TKGeocodable, using geocoder: TKGeocoding, near region: MKMapRect) async throws {
    return try await withCheckedThrowingContinuation { continuation in
      geocode(object, using: geocoder, near: region) { result in
        continuation.resume(with: result)
      }
    }
  }
  
  
  @objc(pickBestFromResults:)
  public class func pickBest(from results: [MKAnnotation]) -> MKAnnotation? {
    if results.count == 0 {
      return nil
    
    } else if results.count == 1, let first = results.first {
      return first
    
    } else {
      return results
        .compactMap { $0 as? TKSortableAnnotation }
        .sorted { return $0.sortScore > $1.sortScore }
        .first
        ?? results.first // if not sortable, pick first
    }
    
  }
  
}

// MARK: - Merging and pruning

extension TKGeocoderHelper {
  @objc public class func mergedAndPruned(_ input:[TKNamedCoordinate], withMaximum max: Int) -> [TKNamedCoordinate] {
    return input.deduplicated().pruned(maximum: max)
  }
  
  public class func pruned(_ input:[TKAutocompletionResult], withMaximum max: Int) -> [TKAutocompletionResult] {
    return input.pruned(maximum: max) { $0.score }
  }
}
  
extension TKNamedCoordinate {
  fileprivate func merge(_ other: TKNamedCoordinate) {
    sortScore = sortScore + min(10, other.sortScore)

    var providers = Set<String>()
    dataSources = (dataSources + other.dataSources).filter { providers.insert($0.provider.name).inserted }
  }
}


extension MKCoordinateRegion {
  static func region(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> MKCoordinateRegion {
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    return MKCoordinateRegion(center: coordinate, span: span)
  }
}

extension Array {

  fileprivate func pruned(maximum max: Int, scoreForElement handler: (Element) -> Int) -> [Element] {
    if self.count < max {
      return self
    }
    
    let sorted = self.sorted { handler($0) >= handler($1) }
    return Array(sorted.prefix(max))
  }
  
}

extension Array where Element : TKNamedCoordinate {

  fileprivate func deduplicated() -> [Element] {
    return reduce([]) { $0.mergeWithPreferences([$1]) }
  }
  
  fileprivate func pruned(maximum max: Int) -> [Element] {
    return pruned(maximum: max) { $0.sortScore }
  }
  
  /// Merges the provided array into `self` removing duplicates and keeping
  /// the preferred elements.
  ///
  /// - SeeAlso: `shouldMerge` and `preferred`
  public func mergeWithPreferences(_ other: [Element]) -> [Element] {
    if other.isEmpty {
      return self
    }
    
    var toRemove: [Element] = []
    var toAdd: [Element] = []
    for new in other {
      // default do adding the new one
      toAdd.append(new)
      
      // check if we should merge with an existing one
      for existing in self where shouldMerge(existing, second: new) {
        if preferred(existing, second: new) == new {
          // replace existing with new
          new.merge(existing)
          toRemove.append(existing)
        } else {
          // don't add new
          existing.merge(new)
          toAdd.removeLast()
        }
        break // merged
      }
    }
    
    return filter { !toRemove.contains($0) } + toAdd
  }

  /// Determines if two coordinates should be merged and only one should be kept.
  private func shouldMerge(_ first: Element, second: Element) -> Bool {
    guard
      let firstTitle = first.title, let secondTitle = second.title,
      firstTitle.contains(secondTitle) || secondTitle.contains(firstTitle)
      else {
        return false
    }
    
    // Only merge same title if they are within a certain distance from
    // each other.
    let firstLocation = CLLocation(latitude: first.coordinate.latitude, longitude: first.coordinate.longitude)
    let secondLocation = CLLocation(latitude: second.coordinate.latitude, longitude: second.coordinate.longitude)
    return firstLocation.distance(from: secondLocation) < 50
  }

  /// Picks which of the two provided named coordinates is the preferred one. The order
  /// of preference is:
  ///
  /// 1. transit stops
  /// 2. coordinates with attribution, e.g., a link to the Foursquare app
  /// 3. higher score
  /// 4. low score
  /// 5. unverified
  ///
  /// - Warning:
  ///   Make sure to call `shouldMerge` first.
  fileprivate func preferred(_ first: Element, second: Element) -> Element {
    if let _ = first as? TKStopCoordinate {
      return first
    } else if let _ = second as? TKStopCoordinate {
      return second
      
    } else if
        let firstIsVerified = first.attributionIsVerified?.boolValue,
        let secondIsVerified = second.attributionIsVerified?.boolValue,
        firstIsVerified != secondIsVerified {
      if firstIsVerified {
        return first
      } else {
        return second
      }
    } else if
        let firstIsVerified = first.attributionIsVerified?.boolValue,
        !firstIsVerified,
        second.attributionIsVerified == nil {
      return second
    } else if
        let secondIsVerified = second.attributionIsVerified?.boolValue,
        !secondIsVerified,
        first.attributionIsVerified == nil {
      return first
        
    } else if !first.dataSources.isEmpty, second.dataSources.isEmpty {
      return first
    } else if first.dataSources.isEmpty, !second.dataSources.isEmpty {
      return second
      
    } else if first.sortScore >= second.sortScore {
      return first
    } else {
      return second
    }
  }
}
