//
//  TKRegion+ModeInfo.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKRegion {
  
  public struct RoutingMode: Hashable {
    public let identifier: String
    public let title: String
    public var subtitle: String? = nil
    public var website: URL? = nil
    public var color: TKColor? = nil
    
    fileprivate let localImageName: String
    fileprivate var remoteImageName: String? = nil
    public var remoteImageIsTemplate: Bool = false
    public var remoteImageIsBranding: Bool = false
    
    static func buildForTesting(_ identifier: String) -> Self {
      return RoutingMode(identifier: identifier, title: identifier, localImageName: "meh")
    }
  }
  
  public var routingModes: [RoutingMode] {
    var modes = modeIdentifiers
    if self != TKRegion.international {
      modes += [TKTransportModeIdentifierWheelchair]
    }
    return modes.compactMap(TKRegionManager.shared.buildRoutingMode)
  }
  
}

extension TKRegion.RoutingMode {
  public var image: TKImage? {
    return self.image(type: .listMainMode)
  }
  
  public var imageURL: URL? {
    return self.imageURL(type: .listMainMode)
  }
  
  public func image(type: TKStyleModeIconType) -> TKImage? {
    return TKStyleManager.image(forModeImageName: localImageName, isRealTime: false, of: type)
  }
  
  public func imageURL(type: TKStyleModeIconType) -> URL? {
    return remoteImageName.map { TKServer.imageURL(iconFileNamePart: $0, iconType: type) } ?? nil
  }

}

fileprivate extension TKRegionManager {
  func buildRoutingMode(modeIdentifier: String) -> TKRegion.RoutingMode? {
    guard
      let title = title(forModeIdentifier: modeIdentifier),
      let localImageName = TKTransportModes.modeImageName(forModeIdentifier: modeIdentifier)
    else {
      TKLog.debug("TKRegion", text: "A mode without a title or local image in regions.json: \(modeIdentifier)")
      return nil
    }
    
    return TKRegion.RoutingMode(
      identifier: modeIdentifier,
      title: title,
      subtitle: subtitle(forModeIdentifier: modeIdentifier),
      website: websiteURL(forModeIdentifier: modeIdentifier),
      color: color(forModeIdentifier: modeIdentifier),
      localImageName: localImageName,
      remoteImageName: remoteImageName(forModeIdentifier: modeIdentifier),
      remoteImageIsTemplate: false,
      remoteImageIsBranding: true
    )

  }
}
