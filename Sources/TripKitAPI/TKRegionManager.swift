//
//  TKRegionManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26.09.17.
//
//

import Foundation

#if canImport(MapKit)
import CoreLocation
import MapKit
#endif

public extension NSNotification.Name {
  /// Always posted on the main thread
  static let TKRegionManagerUpdatedRegions = NSNotification.Name(rawValue: "TKRegionManagerRegionsUpdatedNotification")
}

public class TKRegionManager: NSObject {
  public static let shared = TKRegionManager()
  
  private var response: TKAPI.RegionsResponse? {
    didSet {
      _requiredForModes = nil
    }
  }
  
  private var _requiredForModes: [String: [String]]?
  
  var fetchTask: Task<Void, Error>? = nil

  private override init() {
    super.init()
    Task {
      await loadRegionsFromCache()
    }
  }
  
  @MainActor
  public func loadRegionsFromCache() async {
    do {
      let response = try await Task<TKAPI.RegionsResponse?, Error>.detached(priority: .utility) {
        guard let data = TKRegionManager.readLocalCache() else { return nil }
        return try JSONDecoder().decode(TKAPI.RegionsResponse.self, from: data)
      }.value
      if let response {
        updateRegions(from: response)
      }

    } catch {
      // TKLog.warn("Couldn't load regions from cache: \(error)")
      assertionFailure()
    }
  }
  
  public var hasRegions: Bool {
    return response != nil
  }
  
  public var regions: [TKRegion] {
    return response?.regions ?? []
  }
  
  public var regionsHash: NSNumber? {
    if let hashCode = response?.hashCode {
      return NSNumber(value: hashCode + 2) // Force update after broken polygons
    } else {
      return nil;
    }
  }
  
  
}

// MARK: - Updating regions data

extension TKRegionManager {

  @MainActor
  func updateRegions(from response: TKAPI.RegionsResponse) {
    // Silently ignore obviously bad data
    guard response.modes != nil, response.regions != nil else {
      // This asset isn't valid, due to race conditions
      // assert(self.response?.hashCode == response.hashCode)
      return
    }
    
    self.response = response
    NotificationCenter.default.post(name: .TKRegionManagerUpdatedRegions, object: self)
    
    if let encoded = try? JSONEncoder().encode(response) {
      TKRegionManager.saveToCache(encoded)
    }
  }
  
  public static var cacheURL: URL {
    let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
    return urls.first!.appendingPathComponent("regions.json")
  }
  
  public static func readLocalCache() -> Data? {
    return try? Data(contentsOf: cacheURL)
  }
    
  public static func saveToCache(_ data: Data) {
    try? data.write(to: cacheURL)
  }
  
}

// MARK: - Getting mode details

extension TKRegionManager {

  /// - Parameter mode: The mode identifier for which you want the title
  /// - Returns: The localized title as defined by the server
  public func title(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.title
  }

  /// - Parameter mode: The mode identifier for which you want the title
  /// - Returns: The localized subtitle as defined by the server
  public func subtitle(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.subtitle
  }

  /// - Parameter mode: The mode identifier for which you want the official website URL
  /// - Returns: The URL as defined by the server
  public func websiteURL(forModeIdentifier mode: String) -> URL? {
    return response?.modes?[mode]?.websiteURL
  }
  
#if !os(Linux)
  /// - Parameter mode: The mode identifier for which you want the official color
  /// - Returns: The color as defined by the server
  public func color(forModeIdentifier mode: String) -> TKColor? {
    return response?.modes?[mode]?.rgbColor.color
  }
#endif

  /// - Returns: If specified mode identifier is required and can't get disabled.
  public func modeIdentifierIsRequired(_ mode: String) -> Bool {
    return response?.modes?[mode]?.required ?? false
  }
  
  /// - Returns: List of modes that this mode implies, i.e., enabling the specified modes should also enable all the returned modes.
  public func impliedModes(byModeIdentifer mode: String) -> [String] {
    return response?.modes?[mode]?.implies ?? []
  }
  
  /// - Returns: List of modes that are dependent on this mode, i.e., disabling this mode should also disable all the returned modes.
  public func dependentModeIdentifier(forModeIdentifier mode: String) -> [String] {
    return self.requiredForModes[mode] ?? []
  }
  
  private var requiredForModes: [String: [String]] {
    get {
      if let required = _requiredForModes {
        return required
      }
      guard let details = response?.modes else { return [:] }
      
      var result = [String: [String]]()
      for (mode, detail) in details {
        guard let implies = detail.implies, !implies.isEmpty else { continue }
        for impliedMode in implies {
          result[impliedMode] = (result[impliedMode] ?? []) + [mode]
        }
      }
      _requiredForModes = result
      return result
    }
  }
  
}

// MARK: - Testing coordinates

extension TKRegionManager {
 
#if canImport(CoreLocation)
  public func coordinateIsPartOfAnyRegion(_ coordinate: CLLocationCoordinate2D) -> Bool {
    for region in regions {
      if region.contains(coordinate) {
        return true
      }
    }
    return false
  }
#endif
  
#if canImport(MapKit)
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
#endif
}

// MARK: - Getting regions by coordinates, etc.

extension TKRegionManager {

  /// - Parameter name: A region code
  /// - Returns: The local (non-international) region matching the provided code
  @available(*, deprecated, renamed: "localRegion(code:)")
  public func localRegion(named name: String) -> TKRegion? {
    localRegion(code: name)
  }
  
  /// - Parameter code: A region code
  /// - Returns: The local (non-international) region matching the provided code
  public func localRegion(code: String) -> TKRegion? {
    return regions.first { $0.code == code }
  }
  
#if canImport(MapKit)
  /// - Returns: A matching local region or the shared instance of `TKInternationalRegion` if no local region contains this coordinate region.
  public func region(containing region: MKCoordinateRegion) -> TKRegion {
    return self.region(containing: region.topLeft, region.bottomRight)
  }

  /// - Returns: Local regions that overlap with the provided coordinate region. Can be empty.
  public func localRegions(overlapping region: MKCoordinateRegion) -> [TKRegion] {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    return regions.filter { $0.intersects(mapRect) }
  }
#endif

#if canImport(CoreLocation)
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
    
    let startRegions  = localRegions(containing: start)
    let endRegions    = localRegions(containing: end)
    
    if let intersectingRegion = startRegions.intersection(endRegions).first {
      return [intersectingRegion]
    
    } else {
      return [startRegions, endRegions].compactMap { $0.first }
    }
    
  }

  /// - Parameter coordinate: A coordinate
  /// - Returns: The local (non-international) regions intersecting with the 
  ///     provided coordinate
  public func localRegions(containing coordinate: CLLocationCoordinate2D) -> Set<TKRegion> {
    guard coordinate.isValid else { return [] }
    let containing = regions.filter { $0.contains(coordinate) }
    return Set(containing)
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
      return .international
    }
  }
  
  
  /// - Parameter coordinate: A valid coordinate
  /// - Returns: The time zone of a matching region for this coordinate. Will 
  ///     return `nil` if the coordinate falls outside any supported region.
  public func timeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
    return regions.first { $0.contains(coordinate) }?.timeZone
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
#endif    
  
}
