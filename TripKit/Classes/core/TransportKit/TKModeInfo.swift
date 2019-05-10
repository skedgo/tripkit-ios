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

/// Information to identify and display a mode. Kind of like the
/// big sibling of a mode identifier string.
public class TKModeInfo: NSObject, Codable, NSSecureCoding {
  @objc public let identifier: String?

  /// Text representation of the image
  @objc public let alt: String

  @objc public let localImageName: String?
  @objc public let remoteImageName: String?
  private let remoteIconIsTemplate: Bool?
  @objc public var remoteImageIsTemplate: Bool {
    return remoteIconIsTemplate ?? false
  }
  
  /// Additional descriptor for image, e.g., "GoGet", "Shuttle"
  @objc public let descriptor: String?
  
  private let rgbColor: API.RGBColor?

  @objc public var color: TKColor? {
    return rgbColor?.color
  }

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
      && descriptor == other.descriptor
      && rgbColor == other.rgbColor
  }
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case identifier
    case alt
    case localImageName = "localIcon"
    case remoteImageName = "remoteIcon"
    case remoteIconIsTemplate
    case descriptor
    case rgbColor = "color"
  }
  
  // MARK: NSSecure coding
  
  @objc
  public static var supportsSecureCoding: Bool { return true }

  @objc(encodeWithCoder:)
  public func encode(with aCoder: NSCoder) {
    guard let data = try? JSONEncoder().encode(self) else { return }
    aCoder.encode(data)
  }
  
  @objc
  public required init?(coder aDecoder: NSCoder) {
    if let data = aDecoder.decodeData() {
      // The new way
      do {
        let decoded = try JSONDecoder().decode(TKModeInfo.self, from: data)
        identifier = decoded.identifier
        alt = decoded.alt
        localImageName = decoded.localImageName
        remoteImageName = decoded.remoteImageName
        remoteIconIsTemplate = decoded.remoteIconIsTemplate
        descriptor = decoded.descriptor
        rgbColor = decoded.rgbColor
      } catch {
        assertionFailure("Couldn't decode due to: \(error)")
        return nil
      }
      
    } else {
      // For backwards compatibility
      alt = (aDecoder.decodeObject(forKey: "alt") as? String) ?? ""
      identifier = aDecoder.decodeObject(forKey: "identifier") as? String
      localImageName = aDecoder.decodeObject(forKey: "localIcon") as? String
      remoteImageName = aDecoder.decodeObject(forKey: "remoteIcon") as? String
      descriptor = aDecoder.decodeObject(forKey: "description") as? String
      if let color = aDecoder.decodeObject(forKey: "color") as? TKColor {
        rgbColor = API.RGBColor(for: color)
      } else {
        rgbColor = nil
      }
      remoteIconIsTemplate = false // new property
    }
  }
}
