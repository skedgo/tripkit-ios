//
//  TKRegionManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 26.09.17.
//
//

import Foundation
import CoreLocation

public extension NSNotification.Name {
  public static let TKRegionManagerUpdatedRegions = NSNotification.Name(rawValue: "SVKRegionManagerRegionsUpdatedNotification")
}

public class TKRegionManager: NSObject {
  @objc
  public static let shared = TKRegionManager()
  
  @objc
  public static let UpdatedRegionsNotification = NSNotification.Name.TKRegionManagerUpdatedRegions
  
  private var response: RegionsResponse? {
    didSet {
      _requiredForModes = nil
    }
  }
  
  private var _requiredForModes: [String: [String]]?

  private override init() {
    super.init()
    loadRegionsFromCache()
  }
  
  public func loadRegionsFromCache() {
    guard let data = TKRegionManager.readLocalCache() else { return }
    updateRegions(from: data)
  }
  
  @objc public var hasRegions: Bool {
    return response != nil
  }
  
  @objc public var regions: [SVKRegion] {
    return response?.regions ?? []
  }
  
  @objc public var regionsHash: NSNumber? {
    if let hashCode = response?.hashCode {
      return NSNumber(value: hashCode)
    } else {
      return nil;
    }
  }
  
  
}

// MARK: - Parsing {

struct RegionsResponse: Codable {
  let modes: [String: ModeDetails]?
  let regions: [SVKRegion]?
  let hashCode: Int
}

struct ModeDetails: Codable {
  private enum CodingKeys: String, CodingKey {
    case title
    case websiteURL = "URL"
    case rgbColor = "color"
    case required
    case implies
    case icon
    case darkIcon
    case vehicleIcon
  }
  
  let title: String
  let websiteURL: URL?
  let rgbColor: API.RGBColor
  let required: Bool?
  let implies: [String]?
  let icon: String?
  let darkIcon: String?
  let vehicleIcon: String?
  
  var color: SGKColor {
    return rgbColor.color
  }
}

// MARK: - Updating regions data

extension TKRegionManager {

  @objc(updateRegionsFromData:)
  public func updateRegions(from data: Data) {
    do {
      let response = try JSONDecoder().decode(RegionsResponse.self, from: data)
      
      // Silently ignore if region didn't change
      guard response.modes != nil, response.regions != nil else {
        assert(self.response?.hashCode == response.hashCode)
        return
      }
      
      self.response = response
      TKRegionManager.saveToCache(data)
      
      NotificationCenter.default.post(name: .TKRegionManagerUpdatedRegions, object: self)
      NotificationCenter.default.post(name: .SGMapShouldRefreshOverlay, object: self)

    } catch {
      SGKLog.warn("TKRegionManager", text: "Failed to parse regions: \(error)")
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

// MARK: - Getting mode details {

extension TKRegionManager {

  /// - Parameter mode: The mode identifier for which you want the title
  /// - Returns: The localized title as defined by the server
  @objc
  public func title(forModeIdentifier mode: String) -> String? {
    return response?.modes?[mode]?.title
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
  public func color(forModeIdentifier mode: String) -> SGKColor? {
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
  

  
  @objc(imageURLForModeIdentifier:ofIconType:)
  public func imageURL(forModeIdentifier mode: String?, iconType: SGStyleModeIconType) -> URL? {
    guard
      let mode = mode,
      let details = response?.modes?[mode]
      else { return nil }
    
    var part: String?
    switch iconType {
    case .mapIcon, .listMainMode, .resolutionIndependent:
      part = details.icon
    case .listMainModeOnDark, .resolutionIndependentOnDark:
      part = details.darkIcon
    case .vehicle:
      part = details.vehicleIcon
    case .alert:
      part = nil // not supported for modes
    }
    guard let fileNamePart = part else { return nil }
    return SVKServer.imageURL(forIconFileNamePart: fileNamePart, of: iconType)
  }

}

// MARK: - Testing coordinates {

extension TKRegionManager {
 
  @objc(coordinateIsPartOfAnyRegion:)
  public func coordinateIsPartOfAnyRegion(_ coordinate: CLLocationCoordinate2D) -> Bool {
    for region in regions {
      if region.contains(coordinate) {
        return true
      }
    }
    return false
  }
  
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
}

// MARK: - Getting regions by coordinates, etc.



extension TKRegionManager {
  
  /// - Returns: A matching local region or the shared instance of `SVKInternationalRegion` if no local region contains this coordinate region.
  @objc(regionContainingCoordinateRegion:)
  public func region(containing region: MKCoordinateRegion) -> SVKRegion {
    return self.region(containing: region.topLeft, region.bottomRight)
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
  @objc(localRegionsForStart:andEnd:)
  public func localRegions(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) -> [SVKRegion] {
    
    let startRegions  = localRegions(containing: start)
    let endRegions    = localRegions(containing: end)
    
    if let intersectingRegion = startRegions.intersection(endRegions).first {
      return [intersectingRegion]
    
    } else {
      return [startRegions, endRegions].flatMap { $0.first }
    }
    
  }
  
  
  /// - Returns: Local regions that overlap with the provided coordinate region. Can be empty.
  @objc(localRegionsOverlappingCoordinateRegion:)
  public func localRegions(overlapping region: MKCoordinateRegion) -> [SVKRegion] {
    let mapRect = MKMapRect.forCoordinateRegion(region)
    return regions.filter { $0.intersects(mapRect) }
  }
  

  /// - Parameter coordinate: A coordinate
  /// - Returns: The local (non-international) regions intersecting with the 
  ///     provided coordinate
  @objc(localRegionsContainingCoordinate:)
  public func localRegions(containing coordinate: CLLocationCoordinate2D) -> Set<SVKRegion> {
    guard coordinate.isValid else { return [] }
    
    let containing = regions.filter { $0.contains(coordinate) }
    return Set(containing)
  }
  
  
  /// - Parameter name: A region code
  /// - Returns: The local (non-international) region matching the provided code
  @objc(localRegionWithName:)
  public func localRegion(named name: String) -> SVKRegion? {
    return regions.first { $0.name == name }
  }
  
  
  /// Determines a region (local or international) for the coordinate pair
  ///
  /// - Parameters:
  ///   - first: A valid coordinate
  ///   - second: Another valid coordinate
  /// - Returns: A local region if both lie within the same or the shared
  ///     international region instance.
  @objc(regionContainingCoordinate:andOther:)
  public func region(containing first: CLLocationCoordinate2D, _ second: CLLocationCoordinate2D) -> SVKRegion {
    let local = localRegions(start: first, end: second)
    if local.count == 1 {
      return local.first!
    } else {
      return SVKInternationalRegion.shared
    }
  }
  
  
  /// - Parameter coordinate: A valid coordinate
  /// - Returns: The time zone of a matching region for this coordinate. Will 
  ///     return `nil` if the coordinate falls outside any supported region.
  @objc(timeZoneForCoordinate:)
  public func timeZone(for coordinate: CLLocationCoordinate2D) -> TimeZone? {
    return localRegions(containing: coordinate).first?.timeZone
  }
  
  
  /// Find city closest to provided coordinate, in same region
  ///
  /// - Parameter target: Coordinate for which to find closest city
  /// - Returns: Nearest City
  @objc(cityNearestToCoordinate:)
  public func city(nearestTo target: CLLocationCoordinate2D) -> SVKRegion.City? {
    typealias Match = (SVKRegion.City, CLLocationDistance)
    
    let cities = localRegions(containing: target).reduce(mutating: [SVKRegion.City]()) { cities, region in
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
