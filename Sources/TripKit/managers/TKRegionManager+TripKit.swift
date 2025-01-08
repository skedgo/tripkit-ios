//
//  TKRegionManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26.09.17.
//
//

import Foundation

import CoreLocation
import MapKit

extension TKRegionManager {
  @MainActor
  public func requireRegion(for coordinate: CLLocationCoordinate2D) async throws -> TKRegion {
    try await requireRegions()
    return self.region(containing: coordinate, coordinate)
  }

  @MainActor
  public func requireRegion(for coordinateRegion: MKCoordinateRegion) async throws -> TKRegion {
    try await requireRegions()
    return self.region(containing: coordinateRegion)
  }

  public func coordinateIsPartOfAnyRegion(_ coordinate: CLLocationCoordinate2D) -> Bool {
    return coordinateIsPartOfAnyRegion(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
  /// Used to check if user can route in that area.
  public func mapRectIntersectsAnyRegion(_ mapRect: MKMapRect) -> Bool {
    // TODO: How to handle rect spanning 180th medidian?
    for region in regions {
      if region.intersects(mapRect) {
        return true
      }
    }
    return false
  }
  
  /// - Returns: A matching local region or the shared instance of `TKInternationalRegion` if no local region contains this coordinate region.
  public func region(containing region: MKCoordinateRegion) -> TKRegion {
    return self.region(containing: region.topLeft, region.bottomRight)
  }

  /// - Returns: Local regions that overlap with the provided coordinate region. Can be empty.
  public func localRegions(overlapping region: MKCoordinateRegion) -> [TKRegion] {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    return regions.filter { $0.intersects(mapRect) }
  }

  
  /// Determines the local (non-international) regions for the coordinate pair
  ///
  /// - Parameters:
  ///   - start: A valid coordinate
  ///   - end: Another valid coordinate
  /// - Returns: An array of either A) no element (if both coordinates are in the
  ///     international region), B) one element (if both coordinates are in the
  ///     the same region, or C) two elements (a local region for the start and
  ///     one for the end coordinates).
  public func localRegions(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> [TKRegion] {
    guard start.isValid, end.isValid else { return [] }
    return localRegions(start: (latitude: start.latitude, longitude: start.longitude), end: (latitude: end.latitude, longitude: end.longitude))
  }
  
  /// - Parameter coordinate: A coordinate
  /// - Returns: The local (non-international) regions intersecting with the
  ///     provided coordinate
  public func localRegions(containing coordinate: CLLocationCoordinate2D) -> Set<TKRegion> {
    guard coordinate.isValid else { return [] }
    return localRegions(containingLatitude: coordinate.latitude, longitude: coordinate.longitude)
  }

  /// Determines a region (local or international) for the coordinate pair
  ///
  /// - Parameters:
  ///   - first: A valid coordinate
  ///   - second: Another valid coordinate
  /// - Returns: A local region if both lie within the same or the shared
  ///     international region instance.
  public func region(containing first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> TKRegion {
    let local = localRegions(start: first, end: second)
    if local.count == 1 {
      return local.first!
    } else {
      return TKRegion.international
    }
  }
  
  
  /// - Parameter coordinate: A valid coordinate
  /// - Returns: The time zone of a matching region for this coordinate. Will
  ///     return `nil` if the coordinate falls outside any supported region.
  public func timeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
    return timeZone(containingLatitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
  
  /// Find city closest to provided coordinate, in same region
  ///
  /// - Parameter target: Coordinate for which to find closest city
  /// - Returns: Nearest City
  public func city(nearestTo target: CLLocationCoordinate2D) -> TKRegion.City? {
    typealias Match = (TKRegion.City, CLLocationDistance)
    
    let cities = localRegions(containing: target).reduce(into: [TKRegion.City]()) { cities, region in
      cities.append(contentsOf: region.cities)
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
}

extension TKRegionManager {
  func remoteImageName(forModeIdentifier mode: String) -> String? {
    return modeDetails(forModeIdentifier: mode)?.icon
  }
  
  public func remoteImageIsTemplate(forModeIdentifier mode: String) -> Bool {
    return modeDetails(forModeIdentifier: mode)?.isTemplate ?? false
  }
  
  public func remoteImageIsBranding(forModeIdentifier mode: String) -> Bool {
    return modeDetails(forModeIdentifier: mode)?.isBranding ?? false
  }

  public func imageURL(forModeIdentifier mode: String?, iconType: TKStyleModeIconType) -> URL? {
    guard
      let mode = mode,
      let details = modeDetails(forModeIdentifier: mode)
      else { return nil }
    
    var part: String?
    switch iconType {
    case .mapIcon, .listMainMode, .resolutionIndependent:
      part = details.icon
    case .vehicle:
      part = details.vehicleIcon
    case .alert:
      part = nil // not supported for modes
    @unknown default:
      part = nil
    }
    guard let fileNamePart = part else { return nil }
    return TKServer.imageURL(iconFileNamePart: fileNamePart, iconType: iconType)
  }  
}

extension TKRegionManager {
   public static func sortedModes(in regions: [TKRegion]) -> [TKRegion.RoutingMode] {
    let all = regions.map(\.routingModes)
    return sortedFlattenedModes(all)
  }
  
  static func sortedFlattenedModes(_ modes: [[TKRegion.RoutingMode]]) -> [TKRegion.RoutingMode] {
    guard let first = modes.first else { return [] }
    
    var added = Set<String>()
    added = added.union(first.map(\.identifier))
    var all = first
    
    for group in modes.dropFirst() {
      for (index, mode) in group.enumerated() where !added.contains(mode.identifier) {
        added.insert(mode.identifier)
        
        if index > 0, let previousIndex = all.firstIndex(of: group[index - 1]) {
          all.insert(mode, at: previousIndex + 1)
        } else if index == 0 {
          all.insert(mode, at: 0)
        } else {
          assertionFailure("We're merging in sequence here; how come the previous element isn't in the list? Previous is: \(group[index - 1]) from \(group)")
          all.append(mode)
        }
      }
    }
    
    // Remove specific modes for which we have the generic one
    for mode in all {
      let generic = TKTransportMode.genericModeIdentifier(forModeIdentifier: mode.identifier)
      if generic != mode.identifier, added.contains(generic) {
        added.remove(mode.identifier)
        all.removeAll { $0.identifier == mode.identifier }
      }
    }
    
    return all
  } 
}
