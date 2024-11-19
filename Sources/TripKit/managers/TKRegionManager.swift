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
  @objc
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
      TKLog.warn("Couldn't load regions from cache: \(error)")
      assertionFailure()
    }
  }
  
  @objc public var hasRegions: Bool {
    return response != nil
  }
  
  @objc public var regions: [TKRegion] {
    return response?.regions ?? []
  }
  
  @objc public var regionsHash: NSNumber? {
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
  @objc
  public func title(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.title
  }

  /// - Parameter mode: The mode identifier for which you want the title
  /// - Returns: The localized subtitle as defined by the server
  @objc
  public func subtitle(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.subtitle
  }

  /// - Parameter mode: The mode identifier for which you want the official website URL
  /// - Returns: The URL as defined by the server
  @objc
  public func websiteURL(forModeIdentifier mode: String) -> URL? {
    return response?.modes?[mode]?.websiteURL
  }
  
  /// - Parameter mode: The mode identifier for which you want the official color
  /// - Returns: The color as defined by the server
  @objc
  public func color(forModeIdentifier mode: String) -> TKColor? {
    return response?.modes?[mode]?.color
  }
  
  /// - Returns: If specified mode identifier is required and can't get disabled.
  @objc
  public func modeIdentifierIsRequired(_ mode: String) -> Bool {
    return response?.modes?[mode]?.required ?? false
  }
  
  /// - Returns: List of modes that this mode implies, i.e., enabling the specified modes should also enable all the returned modes.
  @objc(impliedModeIdentifiers:)
  public func impliedModes(byModeIdentifer mode: String) -> [String] {
    return response?.modes?[mode]?.implies ?? []
  }
  
  /// - Returns: List of modes that are dependent on this mode, i.e., disabling this mode should also disable all the returned modes.
  @objc(dependentModeIdentifiers:)
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
  
  func remoteImageName(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.icon
  }
  
  public func remoteImageIsTemplate(forModeIdentifier mode: String) -> Bool {
    return response?.modes?[mode]?.isTemplate ?? false
  }
  
  public func remoteImageIsBranding(forModeIdentifier mode: String) -> Bool {
    return response?.modes?[mode]?.isBranding ?? false
  }

  @objc(imageURLForModeIdentifier:ofIconType:)
  public func imageURL(forModeIdentifier mode: String?, iconType: TKStyleModeIconType) -> URL? {
    guard
      let mode = mode,
      let details = response?.modes?[mode]
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
  
  public static func sortedModes(in regions: [TKRegion]) -> [TKRegion.RoutingMode] {
    let all = regions.map { $0.routingModes }
    return sortedFlattenedModes(all)
  }
  
  static func sortedFlattenedModes(_ modes: [[TKRegion.RoutingMode]]) -> [TKRegion.RoutingMode] {
    guard let first = modes.first else { return [] }
    
    var added = Set<String>()
    added = added.union(first.map { $0.identifier })
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

// MARK: - Testing coordinates

extension TKRegionManager {
 
#if canImport(CoreLocation)
  @objc(coordinateIsPartOfAnyRegion:)
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
  @objc(mapRectIntersectsAnyRegion:)
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
  @objc(localRegionWithName:)
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
  @objc(regionContainingCoordinateRegion:)
  public func region(containing region: MKCoordinateRegion) -> TKRegion {
    return self.region(containing: region.topLeft, region.bottomRight)
  }

  /// - Returns: Local regions that overlap with the provided coordinate region. Can be empty.
  @objc(localRegionsOverlappingCoordinateRegion:)
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
  @objc(localRegionsForStart:andEnd:)
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
  @objc(localRegionsContainingCoordinate:)
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
  @objc(regionContainingCoordinate:andOther:)
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
  @objc(timeZoneForCoordinate:)
  public func timeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
    return regions.first { $0.contains(coordinate) }?.timeZone
  }
  
  
  /// Find city closest to provided coordinate, in same region
  ///
  /// - Parameter target: Coordinate for which to find closest city
  /// - Returns: Nearest City
  @objc(cityNearestToCoordinate:)
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
