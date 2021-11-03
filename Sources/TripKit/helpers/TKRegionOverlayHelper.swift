//
//  TKRegionOverlayHelper.swift
//  TripKit
//
//  Created by Adrian Schönig on 19.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

@objc
public class TKRegionOverlayHelper: NSObject {

  @objc(sharedInstance)
  public static let shared = TKRegionOverlayHelper()
  
  private var regionsOverlay: MKPolygon?
  private var calculationToken: Int?
  
  private var callbacks = [(MKPolygon?) -> Void]()
  
  private override init() {
    super.init()
  }
  
  @objc(regionsPolygonForcingUpdate:completion:)
  public func regionsPolygon(forceUpdate: Bool = false, completion: @escaping (MKPolygon?) -> Void) {

    if (forceUpdate) {
      regionsOverlay = nil
      TKRegionOverlayHelper.deleteCache()
    }
    
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
      let calculationToken = TKRegionManager.shared.regionsHash?.intValue
      self.calculationToken = calculationToken
      
      MKPolygon.union(polygons) { result in
        // Ignore callbacks for since outdated regions (e.g., switching servers quickly)
        guard calculationToken == self.calculationToken else { return }
        
        switch result {
        case .success(let regionPolygons):
          // create outside polygon removing the regions (to show which area is covered)
          let encodable = regionPolygons.map(EncodablePolygon.init)
          TKRegionOverlayHelper.savePolygonsToCacheFile(encodable)
          let overlay = MKPolygon(rectangle: .world, interiorPolygons: regionPolygons)
          self.regionsOverlay = overlay
          for callback in self.callbacks {
            callback(overlay)
          }

        case .failure(let error):
          TKLog.warn("TKRegionOverlayHelper", text: "Polygon union failed: \(error)")
          self.regionsOverlay = nil
          for callback in self.callbacks {
            callback(nil)
          }
        }
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
      MKMapPoint(x: rectangle.maxX, y: rectangle.maxY),
      MKMapPoint(x: rectangle.maxX, y: rectangle.minY),
    ]
    self.init(points: points, count: points.count, interiorPolygons: interiorPolygons)
  }
  
}

class EncodablePolygon: NSObject, NSSecureCoding {
  let polygon: MKPolygon
  
  init(polygon: MKPolygon) {
    self.polygon = polygon
    super.init()
  }
  
  @objc static var supportsSecureCoding: Bool { true }
  
  @objc
  required init?(coder aDecoder: NSCoder) {
    guard
      let degrees = aDecoder.decodeObject(of: [NSNumber.self, NSArray.self], forKey: "degrees") as? [NSNumber]
      else { return nil }
    
    let coordinates = (0..<(degrees.count / 2))
      .map { CLLocationCoordinate2D(latitude: degrees[2*$0].doubleValue, longitude: degrees[2*$0 + 1].doubleValue) }
    
    let interiorPolygons: [MKPolygon]?
    if let interiors = aDecoder.decodeObject(of: [EncodablePolygon.self, NSArray.self], forKey: "interiors") as? [EncodablePolygon] {
      interiorPolygons = interiors.map(\.polygon)
    } else {
      interiorPolygons = nil
    }
    
    self.polygon = MKPolygon(coordinates: coordinates, count: coordinates.count, interiorPolygons: interiorPolygons)
  }
  
  @objc(encodeWithCoder:)
  func encode(with coder: NSCoder) {
    var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: polygon.pointCount)
    let range = NSRange(location: 0, length: polygon.pointCount)
    polygon.getCoordinates(&coordinates, range: range)
    
    let degrees = coordinates
      .flatMap { [$0.latitude, $0.longitude] }
      .map(NSNumber.init)
    coder.encode(degrees, forKey: "degrees")
    
    if let interiors = polygon.interiorPolygons {
      coder.encode(interiors.map(EncodablePolygon.init), forKey: "interiors")
    }
  }
}

// MARK: - Caching on disk

extension TKRegionOverlayHelper {

  public static let cacheURL: URL? = {
    return FileManager.default
      .urls(for: .cachesDirectory, in: .userDomainMask)
      .first?.appendingPathComponent("regionOverlay.data")
  }()
  
  private static func deleteCache() {
    guard let cacheURL = TKRegionOverlayHelper.cacheURL else { return }
    try? FileManager.default.removeItem(at: cacheURL)
  }
  
  private static func loadPolygonsFromCacheFile() -> [MKPolygon]? {
    guard
      let cacheURL = TKRegionOverlayHelper.cacheURL,
      let data = try? Data(contentsOf: cacheURL)
      else { return nil }
    
    do {
      let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
      unarchiver.requiresSecureCoding = false
      
      let regionsHash = unarchiver.decodeObject(of: NSNumber.self, forKey: "regionsHash") as NSNumber?
      guard
        let hash = regionsHash?.intValue,
        hash == TKRegionManager.shared.regionsHash?.intValue
        else { return nil }
      
      
      let wrappedPolygons = unarchiver.decodeObject(of: [EncodablePolygon.self, NSArray.self], forKey: "polygons") as? [EncodablePolygon]
      return wrappedPolygons.map { $0.map(\.polygon) }
      
    } catch {
      assertionFailure("Unexpected error: \(error)")
      return nil
    }
  }
  
  private static func savePolygonsToCacheFile(_ polygons: [EncodablePolygon]) {
    guard
      let cacheURL = TKRegionOverlayHelper.cacheURL,
      !polygons.isEmpty,
      let regionsHash = TKRegionManager.shared.regionsHash
      else { return }
    
    do {
      let archiver = NSKeyedArchiver(requiringSecureCoding: false)
      archiver.encode(polygons, forKey: "polygons")
      archiver.encode(regionsHash, forKey: "regionsHash")
      try archiver.encodedData.write(to: cacheURL)
    } catch {
      assertionFailure()
    }
  }
}
