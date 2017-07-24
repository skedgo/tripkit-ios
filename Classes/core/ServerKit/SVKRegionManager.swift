//
//  SVKRegionManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation
import CoreLocation

extension SVKRegionManager {
  
  public static let shared = SVKRegionManager.__sharedInstance()
  
  /// Determines the local (non-international) regions for the coordinate pair
  ///
  /// - Parameters:
  ///   - start: A valid coordinate
  ///   - end: Another valid coordinate
  /// - Returns: An array of either A) no element (if both coordinates are in the
  ///     international region), B) one element (if both coordinates are in the
  ///     the same region, or C) two elements (a local region for the start and
  ///     one for the end coordinates).
  @objc(localRegionsForStart:andEnd:)
  public func localRegions(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> [SVKRegion] {
    
    let startRegions  = localRegions(for: start)
    let endRegions    = localRegions(for: end)
    
    if let intersectingRegion = startRegions.intersection(endRegions).first {
      return [intersectingRegion]
    
    } else {
      return [startRegions, endRegions].flatMap { $0.first }
    }
    
  }
  
  
  /// - Parameter coordinate: A coordinate
  /// - Returns: The local (non-international) regions intersecting with the 
  ///     provided coordinate
  @objc(localRegionsForCoordinate:)
  public func localRegions(for coordinate: CLLocationCoordinate2D) -> Set<SVKRegion> {
    guard coordinate.isValid, let regions = regions else { return [] }
    
    let containing = regions.filter { $0.contains(coordinate) }
    return Set(containing)
  }
  
  
  /// - Parameter name: A region code
  /// - Returns: The local (non-international) region matching the provided code
  @objc(localRegionWithName:)
  public func localRegion(named name: String) -> SVKRegion? {
    return regions?.first { $0.name == name }
  }
  
  
  /// Determines a region (local or international) for the coordinate pair
  ///
  /// - Parameters:
  ///   - first: A valid coordinate
  ///   - second: Another valid coordinate
  /// - Returns: A local region if both lie within the same or the shared
  ///     international region instance.
  @objc(regionForCoordinate:andOther:)
  public func region(_ first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> SVKRegion {
    return localRegions(start: first, end: second).first ?? SVKInternationalRegion.shared
  }
  
  
  /// - Parameter coordinate: A valid coordinate
  /// - Returns: The time zone of a matching region for this coordinate. Will 
  ///     return `nil` if the coordinate falls outside any supported region.
  @objc(timeZoneForCoordinate:)
  public func timeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
    return localRegions(for: coordinate).first?.timeZone
  }
  
  
  /// Find city closest to provided coordinate, in same region
  ///
  /// - Parameter target: Coordinate for which to find closest city
  /// - Returns: Nearest City
  public func city(nearestTo target: CLLocationCoordinate2D) -> SVKRegion.City? {
    typealias Match = (SVKRegion.City, CLLocationDistance)
    
    let cities = localRegions(for: target).reduce(mutating: []) {
      $0.append(contentsOf: $1.cities)
    }
    let best = cities.reduce(nil) { acc, city -> Match? in
      guard let distance = target.distance(from: city.coordinate) else { return acc }
      
      if let existing = acc?.1, existing < distance {
        return acc
      } else {
        return (city, distance)
      }
    }
    
    return best?.0
  }
  
  
  @objc(updateRegionsFromJSON:)
  public func updateRegions(from json: [String: Any]) {
    guard
      let regions: [SVKRegion] = try? json.value(for: "regions"),
      regions.count > 0,
      let modes:  [String: Any] = try? json.value(for: "modes"),
      let hashCode: Int = try? json.value(for: "hashCode")
      else {
        return
    }
    
    self.updateRegions(regions, modeDetails: modes, hashCode: hashCode)
  }
}

