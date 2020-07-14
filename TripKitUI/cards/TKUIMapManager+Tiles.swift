//
//  TKUIMapManager+Tiles.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 07.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import MapKit

/// Tiles that can be used on a `TKUIMapManager`
public protocol TKUIMapTiles {
  
  /// Unique identifier for this set of tiles
  var id: String { get }
  
  /// A list of URL templates to fetch the tiles. Can be multiple to not hit a single server with too many requests in parallel.
  var urlTemplates: [String] { get }

  /// Attributions to have to be displayed whenever the tiles are displayed
  var sources: [TKAPI.DataAttribution] { get }
}

extension TKMapTiles: TKUIMapTiles {
  public var id: String { name }
}

struct TKUIMapSettings {
  let mapType: MKMapType
}

extension TKUIMapManager {
  func buildTileOverlay(tiles: TKUIMapTiles) -> MKTileOverlay {
    if let existing = Self.tileOverlays[tiles.id] {
      return existing
    } else {
      let overlay = CachedTileOverlay(urlTemplates: tiles.urlTemplates)
      overlay.canReplaceMapContent = true
      
      // TODO: Show attribution view
      
      Self.tileOverlays[tiles.id] = overlay
      return overlay
    }
  }
  
  func accommodateTileOverlay(_ tileOverlay: MKTileOverlay, sources: [TKAPI.DataAttribution], on mapView: MKMapView) -> TKUIMapSettings {
    mapView.addOverlay(tileOverlay, level: .aboveRoads) // so that our other overlays can be above it
    
    let toRestore = TKUIMapSettings(mapType: mapView.mapType)
    if #available(iOS 11.0, *) {
      mapView.mapType = .mutedStandard
    }
    if #available(iOS 13.0, *) {
      mapView.overrideUserInterfaceStyle = .light
      mapView.pointOfInterestFilter = .excludingAll
    }
    
    if let attributionView = TKUIAttributionView.newView(sources) {
      attributionView.translatesAutoresizingMaskIntoConstraints = false
      mapView.addSubview(attributionView)
      NSLayoutConstraint.activate([
        attributionView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
        attributionView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
        attributionView.leadingAnchor.constraint(greaterThanOrEqualTo: mapView.leadingAnchor)
      ])
      
      let tapper = UITapGestureRecognizer(target: self, action: #selector(didTapAttribution))
      attributionView.addGestureRecognizer(tapper)
    }
    
    return toRestore
  }
  
  @objc
  func didTapAttribution(sender: UITapGestureRecognizer) {
    guard
      let sources = tiles?.sources,
      let displayer = attributionDisplayer,
      let view = sender.view
    else { return }
    displayer(sources, view)
  }
  
  func restore(_ mapSettings: TKUIMapSettings, on mapView: MKMapView) {
    mapView.mapType = mapSettings.mapType
    if #available(iOS 13.0, *) {
      mapView.overrideUserInterfaceStyle = .unspecified
      mapView.pointOfInterestFilter = MKPointOfInterestFilter(excluding: [.publicTransport])
    }
    
    mapView.subviews
      .compactMap({ $0 as? TKUIAttributionView })
      .forEach { $0.removeFromSuperview() }
  }
  
}

class CachedTileOverlay: MKTileOverlay {
  
  let urlTemplates: [String]
  
  let tileCache = NSCache<NSString, NSData>()
  
  init(urlTemplates: [String]) {
    self.urlTemplates = urlTemplates
    super.init(urlTemplate: urlTemplates.first)
  }

  override func url(forTilePath path: MKTileOverlayPath) -> URL {
    let template = urlTemplates.randomElement()!
    let filledIn = template
      .replacingOccurrences(of: "{x}", with: String(path.x))
      .replacingOccurrences(of: "{y}", with: String(path.y))
      .replacingOccurrences(of: "{z}", with: String(path.z))
      .replacingOccurrences(of: "{scale}", with: "\(path.contentScaleFactor)")
    return URL(string: filledIn)!
  }
  
  override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
    let key = "\(path.x)-\(path.y)-\(path.z)" as NSString // ignoring scale as we assume it doesn't change
    if let cached = tileCache.object(forKey: key) {
      result(cached as Data, nil)
    } else {
      super.loadTile(at: path) { [weak self] data, error in
        if let data = data {
          self?.tileCache.setObject(data as NSData, forKey: key)
        }
        result(data, error)
      }
    }
  }
  
}
