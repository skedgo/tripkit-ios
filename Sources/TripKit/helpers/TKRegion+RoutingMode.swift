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
    
    fileprivate let localImageName: String?
    fileprivate var remoteImageName: String? = nil
    fileprivate var customImage: TKImage? = nil
    public var remoteImageIsTemplate: Bool = false
    public var remoteImageIsBranding: Bool = false
    
    public init(identifier: String, title: String, subtitle: String? = nil, icon: TKImage) {
      self.identifier = identifier
      self.title = title
      self.subtitle = subtitle
      self.localImageName = nil
      self.customImage = icon
    }
    
    fileprivate init(
      identifier: String,
      title: String,
      subtitle: String? = nil,
      website: URL? = nil,
      color: TKColor? = nil,
      localImageName: String,
      remoteImageName: String? = nil,
      remoteImageIsTemplate: Bool = false,
      remoteImageIsBranding: Bool = false
    ) {
      self.identifier = identifier
      self.title = title
      self.subtitle = subtitle
      self.website = website
      self.color = color
      self.localImageName = localImageName
      self.remoteImageName = remoteImageName
      self.remoteImageIsTemplate = remoteImageIsTemplate
      self.remoteImageIsBranding = remoteImageIsBranding
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.identifier == rhs.identifier
        && lhs.title == rhs.title
        && lhs.subtitle == rhs.subtitle
        && lhs.website == rhs.website
        && lhs.color == rhs.color
        && lhs.localImageName == rhs.localImageName
        && lhs.remoteImageName == rhs.remoteImageName
        && lhs.remoteImageIsTemplate == rhs.remoteImageIsTemplate
        && lhs.remoteImageIsBranding == rhs.remoteImageIsBranding
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(identifier)
      hasher.combine(title)
      hasher.combine(subtitle)
      hasher.combine(website)
      hasher.combine(color)
      hasher.combine(localImageName)
      hasher.combine(remoteImageName)
      hasher.combine(remoteImageIsTemplate)
      hasher.combine(remoteImageIsBranding)
    }
    
    static func buildForTesting(_ identifier: String) -> Self {
      return RoutingMode(identifier: identifier, title: identifier, localImageName: "meh")
    }
  }
  
  public var routingModes: [RoutingMode] {
    var modes = modeIdentifiers
    if self != TKRegion.international {
      modes += [TKTransportMode.wheelchair.modeIdentifier]
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
    return customImage ?? localImageName.flatMap { TKStyleManager.image(forModeImageName: $0, of: type) }
  }
  
  public func imageURL(type: TKStyleModeIconType) -> URL? {
    return remoteImageName.map { TKServer.imageURL(iconFileNamePart: $0, iconType: type) } ?? nil
  }

}

fileprivate extension TKRegionManager {
  func buildRoutingMode(modeIdentifier: String) -> TKRegion.RoutingMode? {
    guard
      let title = title(forModeIdentifier: modeIdentifier),
      let localImageName = TKTransportMode.modeImageName(forModeIdentifier: modeIdentifier)
    else {
      TKLog.debug("A mode without a title or local image in regions.json: \(modeIdentifier)")
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
      remoteImageIsTemplate: remoteImageIsTemplate(forModeIdentifier: modeIdentifier),
      remoteImageIsBranding: remoteImageIsBranding(forModeIdentifier: modeIdentifier)
    )

  }
}
