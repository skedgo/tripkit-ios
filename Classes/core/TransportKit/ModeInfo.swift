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
public class ModeInfo: NSObject, Codable {
  @objc public let identifier: String?

  /// Text representation of the image
  @objc public let alt: String

  @objc public let localImageName: String?
  @objc public let remoteImageName: String?
  @objc public let remoteDarkImageName: String?
  
  /// Additional descriptor for image, e.g., "GoGet", "Shuttle"
  @objc public let descriptor: String?
  
  private let rgbColor: API.RGBColor?

  @objc public var color: SGKColor? {
    return rgbColor?.color
  }

  @objc(modeInfoForDictionary:)
  public class func modeInfo(for json: [String: Any]) -> ModeInfo? {
    let decoder = JSONDecoder()
    return try? decoder.decode(ModeInfo.self, withJSONObject: json)
  }
  
  override private init() {
    identifier = nil
    alt = ""
    localImageName = nil
    remoteImageName = nil
    remoteDarkImageName = nil
    descriptor = nil
    rgbColor = nil
    super.init()
  }
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case identifier
    case alt
    case localImageName = "localIcon"
    case remoteImageName = "remoteIcon"
    case remoteDarkImageName = "remoteDarkIcon"
    case descriptor
    case rgbColor = "color"
  }
  
}
