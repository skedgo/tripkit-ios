//
//  ModeInfo.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

@available(*, unavailable, renamed: "TKModeInfo")
public typealias ModeInfo = TKModeInfo

/// Information to identify and display a transport mode. Kind of like the
/// big sibling of a mode identifier string.
public class TKModeInfo: NSObject, Codable, NSSecureCoding {
  
  /// The mode identifier string. Can be `nil`, e.g., for parking as that can
  /// apply to multiple modes.
  @objc public let identifier: String?

  /// Text representation of the image
  @objc public let alt: String

  /// Image part name; use with `TKStyleManager.image(forModeImageName:)`
  @objc public let localImageName: String?
  
  /// Image part name; use with `TKServer.imageURL(iconFileNamePart:)`
  @objc public let remoteImageName: String?

  /// If true, then `remoteImageName` should be treated as a template image and
  /// have an appropriate colour applied to it.
  @objc public var remoteImageIsTemplate: Bool {
    return remoteIconIsTemplate ?? false
  }
  private let remoteIconIsTemplate: Bool?

  /// If true, `remoteImageIsBranding` points at a brand image and should be
  /// shown next to the local image; if `false` it shoud replace  it.
  @objc public var remoteImageIsBranding: Bool {
    return remoteIconIsBranding ?? false
  }
  private let remoteIconIsBranding: Bool?

  /// Additional descriptor for image, e.g., "GoGet", "Shuttle"
  @objc public let descriptor: String?
  
  @objc public var color: TKColor? {
    return rgbColor?.color
  }
  private let rgbColor: TKAPI.RGBColor?

  @objc(modeInfoForDictionary:)
  public class func modeInfo(for json: [String: Any]?) -> TKModeInfo? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(TKModeInfo.self, withJSONObject: json)
  }
  
  public static let unknown: TKModeInfo = modeInfo(for: ["alt": "unknown"])!
  
  // MARK: Equatable
  
  public override func isEqual(_ object: Any?) -> Bool {
    guard let other = object as? TKModeInfo else { return false }
    return identifier == other.identifier
      && alt == other.alt
      && localImageName == other.localImageName
      && remoteImageName == other.remoteImageName
      && remoteIconIsTemplate == other.remoteIconIsTemplate
      && remoteIconIsBranding == other.remoteIconIsBranding
      && descriptor == other.descriptor
      && rgbColor == other.rgbColor
  }
  
  public override var hash: Int {
    var hasher = Hasher()
    hasher.combine(identifier)
    hasher.combine(alt)
    hasher.combine(localImageName)
    hasher.combine(remoteImageName)
    hasher.combine(remoteIconIsTemplate)
    hasher.combine(remoteIconIsBranding)
    hasher.combine(descriptor)
    hasher.combine(rgbColor)
    return hasher.finalize()
  }
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case identifier
    case alt
    case localImageName = "localIcon"
    case remoteImageName = "remoteIcon"
    case remoteIconIsTemplate
    case remoteIconIsBranding
    case descriptor
    case rgbColor = "color"
  }
  
  // MARK: NSSecure coding
  
  @objc
  public static var supportsSecureCoding: Bool { return true }

  @objc(encodeWithCoder:)
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(alt, forKey: "alt")
    aCoder.encode(identifier, forKey: "identifier")
    aCoder.encode(localImageName, forKey: "localIcon")
    aCoder.encode(remoteImageName, forKey: "remoteIcon")
    aCoder.encode(descriptor, forKey: "description")
    aCoder.encode(color, forKey: "color")
    aCoder.encode(remoteIconIsTemplate, forKey: "remoteIconIsTemplate")
    aCoder.encode(remoteIconIsBranding, forKey: "remoteIconIsBranding")
  }
  
  @objc
  public required init?(coder aDecoder: NSCoder) {
    guard let alt = aDecoder.decodeObject(of: NSString.self, forKey: "alt") as String? else {
      assertionFailure()
      return nil
    }
    self.alt = alt
    identifier = aDecoder.decodeObject(of: NSString.self, forKey: "identifier") as String?
    localImageName = aDecoder.decodeObject(of: NSString.self, forKey: "localIcon") as String?
    remoteImageName = aDecoder.decodeObject(of: NSString.self, forKey: "remoteIcon") as String?
    descriptor = aDecoder.decodeObject(of: NSString.self, forKey: "description") as String?
    if let color = aDecoder.decodeObject(of: TKColor.self, forKey: "color") {
      rgbColor = TKAPI.RGBColor(for: color)
    } else {
      rgbColor = nil
    }
    remoteIconIsTemplate = aDecoder.decodeBool(forKey: "remoteIconIsTemplate")
    remoteIconIsBranding = aDecoder.decodeBool(forKey: "remoteIconIsBranding")
  }
}
