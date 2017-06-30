//
//  ModeInfo.swift
//  Pods
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

import Marshal

/// Information to identify and display a mode. Kind of like the
/// big sibling of a mode identifier string.
public class ModeInfo: NSObject, NSSecureCoding, Unmarshaling {
  public let identifier: String?

  /// Text representation of the image
  public let alt: String

  public let localImageName: String?
  public let remoteImageName: String?
  public let remoteDarkImageName: String?
  
  /// Additional descriptor for image, e.g., "GoGet", "Shuttle"
  public let descriptor: String?
  
  public let color: SGKColor?
  
  @objc(modeInfoForDictionary:)
  public class func modeInfo(for json: [String: Any]) -> ModeInfo? {
    return try? ModeInfo(object: json)
  }
  
  // MARK: NSCoding
  
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(identifier, forKey: "identifier")
    aCoder.encode(alt, forKey: "alt")
    aCoder.encode(localImageName, forKey: "localIcon")
    aCoder.encode(remoteImageName, forKey: "remoteIcon")
    aCoder.encode(remoteDarkImageName, forKey: "remoteDarkIcon")
    aCoder.encode(descriptor, forKey: "description")
    aCoder.encode(color, forKey: "color")
  }
  
  public required init(coder: NSCoder) {
    if let decodedAlt = coder.decodeObject(forKey: "alt") as? String {
      alt = decodedAlt
    } else {
      assertionFailure("Could not get required 'alt'!")
      alt = ""
    }
    
    identifier = coder.decodeObject(forKey: "identifier") as? String
    localImageName = coder.decodeObject(forKey: "localIcon") as? String
    remoteImageName = coder.decodeObject(forKey: "remoteIcon") as? String
    remoteDarkImageName = coder.decodeObject(forKey: "remoteDarkIcon") as? String
    descriptor = coder.decodeObject(forKey: "description") as? String
    color = coder.decodeObject(forKey: "color") as? SGKColor
  }
  
  public static var supportsSecureCoding: Bool { return true }
  
  // MARK: Unmarshaling
  
  public required init(object: MarshaledObject) throws {
    identifier = try? object.value(for: "identifier")
    alt = try object.value(for: "alt")
    localImageName = try? object.value(for: "localIcon")
    remoteImageName = try? object.value(for: "remoteIcon")
    remoteDarkImageName = try? object.value(for: "remoteDarkIcon")
    descriptor = try? object.value(for: "description")
    color = try? object.value(for: "color")
  }
  
}
