//
//  TKRegionOverlayHelper.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import MapKit

@objc
public class TKRegionOverlayHelper: NSObject {

  public static let shared = TKRegionOverlayHelper()
  
  private var regionsOverlay: MKPolygon?
  
  private var callbacks = [(MKPolygon?) -> Void]()
  
  private override init() {
    super.init()
  }
  
  @objc
  public func clearCache() {
    regionsOverlay = nil
    if let cacheURL = TKRegionOverlayHelper.cacheURL {
      try? FileManager.default.removeItem(at: cacheURL)
    }
  }
  
  @objc
  public func regionsPolygon(_ completion: @escaping (MKPolygon?) -> Void) {
    
    if let polygon = regionsOverlay {
      if (polygon.pointCount > 0) {
        completion(polygon)
      } else {
        callbacks.append(completion)
      }
      
    } else if let cached = TKRegionOverlayHelper.loadPolygonsFromCacheFile(), !cached.isEmpty {
      regionsOverlay = MKPolygon(rectangle: .world, interiorPolygons: cached)
      completion(regionsOverlay)
      
    } else {
      // generate it and put a placeholder here
      regionsOverlay = MKPolygon(points: [], count: 0)
      callbacks.append(completion)
      
      let polygons = TKRegionManager.shared.regions.map { $0.polygon }
      MKPolygon.union(polygons) { regionPolygons in
        // create outside polygin (to show which area we cover)
        TKRegionOverlayHelper.savePolygonsToCacheFile(regionPolygons.compactMap { $0 as? (NSCoding & MKPolygon) })
        let overlay = MKPolygon(rectangle: .world, interiorPolygons: regionPolygons)
        for callback in self.callbacks {
          callback(overlay)
        }
        self.regionsOverlay = overlay
        self.callbacks = []
      }
      
    }
    
  }
  
}

// MARK: - Helper

extension MKPolygon {
  
  convenience init(rectangle: MKMapRect, interiorPolygons: [MKPolygon]? = nil) {
    let points: [MKMapPoint] = [
      MKMapPoint(x: rectangle.minX, y: rectangle.minY),
      MKMapPoint(x: rectangle.minX, y: rectangle.maxY),
      MKMapPoint(x: rectangle.maxX, y: rectangle.minY),
      MKMapPoint(x: rectangle.maxX, y: rectangle.maxY),
    ]
    
    self.init(points: points, count: points.count, interiorPolygons: interiorPolygons)
  }
  
}

// MARK: - Caching on disk

extension TKRegionOverlayHelper {

  public static let cacheURL: URL? = {
    return FileManager.default
      .urls(for: .cachesDirectory, in: .userDomainMask)
      .first?.appendingPathComponent("regionOverlay.data")
  }()
  
  private static func loadPolygonsFromCacheFile() -> [MKPolygon]? {
    guard
      let cacheURL = TKRegionOverlayHelper.cacheURL,
      let data = try? Data(contentsOf: cacheURL),
      let unarchived = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: AnyHashable],
      let regionsHash = (unarchived["regionsHash"] as? NSNumber)?.intValue,
      let polygons = unarchived["polygons"] as? [MKPolygon],
      regionsHash == TKRegionManager.shared.regionsHash?.intValue
      else { return nil }
    
    return polygons
  }
  
  private static func savePolygonsToCacheFile(_ polygons: [MKPolygon & NSCoding]) {
    guard
      let cacheURL = TKRegionOverlayHelper.cacheURL,
      !polygons.isEmpty,
      let regionsHash = TKRegionManager.shared.regionsHash
      else { return }
    
    let wrapped: [String: Any] = [
      "polygons": polygons,
      "regionsHash": regionsHash
    ]
    let data = NSKeyedArchiver.archivedData(withRootObject: wrapped)
    try? data.write(to: cacheURL)
  }
}
