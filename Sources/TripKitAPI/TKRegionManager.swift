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
  
  public func modeDetails(forModeIdentifier mode: String) -> TKAPI.ModeDetails? {
    return response?.modes?[mode]
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

// MARK: - Getting regions by coordinates, etc.

extension TKRegionManager {
  
  public func coordinateIsPartOfAnyRegion(latitude: TKAPI.Degrees, longitude: TKAPI.Degrees) -> Bool {
    for region in regions {
      if region.contains(latitude: latitude, longitude: longitude) {
        return true
      }
    }
    return false
  }
  
  public func localRegions(containingLatitude latitude: TKAPI.Degrees, longitude: TKAPI.Degrees) -> Set<TKRegion> {
    let containing = regions.filter { $0.contains(latitude: latitude, longitude: longitude) }
    return Set(containing)
  }
  
  public func localRegions(start: (latitude: TKAPI.Degrees, longitude: TKAPI.Degrees), end: (latitude: TKAPI.Degrees, longitude: TKAPI.Degrees)) -> [TKRegion] {
    let startRegions  = localRegions(containingLatitude: start.latitude, longitude: start.longitude)
    let endRegions    = localRegions(containingLatitude: end.latitude, longitude: end.longitude)
    
    if let intersectingRegion = startRegions.intersection(endRegions).first {
      return [intersectingRegion]
    
    } else {
      return [startRegions, endRegions].compactMap { $0.first }
    }
  }

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
  
  public func timeZone(containingLatitude latitude: TKAPI.Degrees, longitude: TKAPI.Degrees) -> TimeZone? {
    return localRegions(containingLatitude: latitude, longitude: longitude).first?.timeZone
  }
    
}
