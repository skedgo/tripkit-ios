//
//  ModeInfo.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

/// Information to identify and display a mode. Kind of like the
/// big sibling of a mode identifier string.
public class ModeInfo: NSObject, Codable, NSSecureCoding {
  @objc public let identifier: String?

  /// Text representation of the image
  @objc public let alt: String

  @objc public let localImageName: String?
  @objc public let remoteImageName: String?
  private let remoteIconIsTemplate: Bool?
  @objc public let remoteDarkImageName: String?
  @objc public var remoteImageIsTemplate: Bool {
    return remoteIconIsTemplate ?? false
  }
  
  /// Additional descriptor for image, e.g., "GoGet", "Shuttle"
  @objc public let descriptor: String?
  
  private let rgbColor: API.RGBColor?

  @objc public var color: SGKColor? {
    return rgbColor?.color
  }

  @objc(modeInfoForDictionary:)
  public class func modeInfo(for json: [String: Any]?) -> ModeInfo? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(ModeInfo.self, withJSONObject: json)
  }
  
  public static let unknown: ModeInfo = modeInfo(for: ["alt": "unknown"])!
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case identifier
    case alt
    case localImageName = "localIcon"
    case remoteImageName = "remoteIcon"
    case remoteDarkImageName = "remoteDarkIcon"
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
        let decoded = try JSONDecoder().decode(ModeInfo.self, from: data)
        identifier = decoded.identifier
        alt = decoded.alt
        localImageName = decoded.localImageName
        remoteImageName = decoded.remoteImageName
        remoteDarkImageName = decoded.remoteDarkImageName
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
      remoteDarkImageName = aDecoder.decodeObject(forKey: "remoteDarkIcon") as? String
      descriptor = aDecoder.decodeObject(forKey: "description") as? String
      if let color = aDecoder.decodeObject(forKey: "color") as? SGKColor {
        rgbColor = API.RGBColor(for: color)
      } else {
        rgbColor = nil
      }
      remoteIconIsTemplate = false // new property
    }
  }
}
