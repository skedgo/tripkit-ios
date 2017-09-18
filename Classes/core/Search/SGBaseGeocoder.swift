//
//  SGBaseGeocoder.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

extension SGBaseGeocoder {

  @objc public class func filteredMergedAndPruned(_ input:[SGKNamedCoordinate], limitedToRegion coordinateRegion: MKCoordinateRegion, withMaximum max: Int) -> [SGKNamedCoordinate]
  {
    let filtered = input.limitedToRegion(region: coordinateRegion)
    let deduplicated  = filtered.deduplicated()
    return deduplicated.pruned(maximum: max)
  }
  
  @objc public class func filteredAndPruned(_ input:[SGAutocompletionResult], limitedToRegion coordinateRegion: MKCoordinateRegion, withMaximum max: Int, coordinateForElement handler: (SGAutocompletionResult) -> CLLocationCoordinate2D) -> [SGAutocompletionResult]
  {
    let filtered = input.limitedToRegion(coordinateRegion, coordinateForElement: handler)
    return filtered.pruned(maximum: max) { $0.score }
  }
  
  @objc(geocodeObject:usingGeocoder:nearRegion:completion:)
  public class func geocode(_ object: SGKGeocodable, using geocoder: SGGeocoder, near region: MKMapRect, completion: @escaping (Bool) -> Void) {
    
    guard let address = object.addressForGeocoding, address.utf16.count > 0 else {
      completion(false)
      return
    }
    
    geocoder.geocodeString(address, nearRegion: region,
                           success:
      { query, results in
        guard results.count > 0 else {
          completion(false)
          return
        }
        
        let best = SGBaseGeocoder.pickBest(fromResults: results)

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
        completion(true)
        
      },
                           failure:
      { _query, _error in
        completion(false)
      })
    
  }
  
}

extension SGKNamedCoordinate {
  fileprivate func merge(_ other: SGKNamedCoordinate) {
    sortScore = sortScore + min(10, other.sortScore)
    
    if let websiteTitle = other.attributionWebsiteActionTitle,
       let websiteLink = other.attributionWebsiteLink,
       let appTitle = other.attributionAppActionTitle,
       let appLink = other.attributionAppLink,
       attributionWebsiteLink == nil { // enough to check one
      setAttribution(actionTitle: websiteTitle, website: websiteLink, appActionTitle: appTitle, appLink: appLink, isVerified: other.attributionIsVerified)
    }
  }
}

extension MKMapRect {
  public static func forCoordinateRegion(_ region: MKCoordinateRegion) -> MKMapRect
  {
    let a = MKMapPointForCoordinate(CLLocationCoordinate2D(
      latitude: region.center.latitude + region.span.latitudeDelta / 2,
      longitude: region.center.longitude - region.span.longitudeDelta / 2))
    let b = MKMapPointForCoordinate(CLLocationCoordinate2D(
      latitude: region.center.latitude - region.span.latitudeDelta / 2,
      longitude: region.center.longitude + region.span.longitudeDelta / 2))
    
    return MKMapRectMake(min(a.x,b.x), min(a.y,b.y), abs(a.x-b.x), abs(a.y-b.y))
  }
}

extension MKCoordinateRegion {
  public static func region(latitude: CLLocationDegrees, longitude: CLLocationDegrees) -> MKCoordinateRegion {
    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let span = MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    return MKCoordinateRegion(center: coordinate, span: span)
  }
}

extension Array {

  /// - parameter region:  A coordinate region on which the limits will be based
  /// - parameter handler: Block called on every element which should return the coordinate
  ///                      for the provided element if it can be filtered or an invalid
  ///                      coordinate if the element should not get filtered
  /// - returns: A new array limited to `SVKRegions` which intersect with the provided
  ///            coordinate regions
  fileprivate func limitedToRegion(_ region: MKCoordinateRegion, coordinateForElement handler: (Element) -> CLLocationCoordinate2D) -> [Element] {
    
    if SVKRegionManager.shared.hasRegions {
      return filter { element in
        let coordinate = handler(element)
        if !CLLocationCoordinate2DIsValid(coordinate) {
          return true
        } else {
          return SVKRegionManager.shared.regions(for: region, include: coordinate)
        }
      }
      
    } else {
      // This is just meant for running tests
      var largerRegion = region
      largerRegion.span.latitudeDelta *= 2
      largerRegion.span.longitudeDelta *= 2
      let mapRect = MKMapRect.forCoordinateRegion(largerRegion)
      return filter { element in
        let coordinate = handler(element)
        if !CLLocationCoordinate2DIsValid(coordinate) {
          return true
        } else {
          let point = MKMapPointForCoordinate(coordinate)
          return MKMapRectContainsPoint(mapRect, point)
        }
      }
    }
    
  }

  fileprivate func pruned(maximum max: Int, scoreForElement handler: (Element) -> Int) -> [Element] {
    if self.count < max {
      return self
    }
    
    let sorted = self.sorted { handler($0) >= handler($1) }
    return Array(sorted.prefix(max))
  }
  
}

extension Array where Element : SGKNamedCoordinate {

  fileprivate func limitedToRegion(region coordinateRegion: MKCoordinateRegion) -> [Element] {
    return limitedToRegion(coordinateRegion) { $0.coordinate }
  }

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
  func mergeWithPreferences(_ other: [Element]) -> [Element] {
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
    if let _ = first as? STKStopCoordinate {
      return first
    } else if let _ = second as? STKStopCoordinate {
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
        
    } else if first.attributionAppLink != nil, second.attributionAppLink == nil {
      return first
    } else if first.attributionAppLink == nil, second.attributionAppLink != nil {
      return second
      
    } else if first.sortScore >= second.sortScore {
      return first
    } else {
      return second
    }
  }
}
