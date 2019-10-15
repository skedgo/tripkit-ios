//
//  TKMiniInstruction.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public class TKMiniInstruction: NSObject, Codable, NSSecureCoding {
  public let instruction: String
  public let mainValue: String?
  public let detail: String?
  
  private enum CodingKeys: String, CodingKey {
    case instruction
    case mainValue
    case detail = "description"
  }
  
  public static func instruction(for json: [String: Any]?) -> TKMiniInstruction? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(TKMiniInstruction.self, withJSONObject: json)
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
        let decoded = try JSONDecoder().decode(TKMiniInstruction.self, from: data)
        instruction = decoded.instruction
        mainValue = decoded.mainValue
        detail = decoded.detail
      } catch {
        assertionFailure("Couldn't decode due to: \(error)")
        return nil
      }
      
    } else {
      // For backwards compatibility
      instruction = (aDecoder.decodeObject(forKey: "instruction") as? String) ?? ""
      mainValue = aDecoder.decodeObject(forKey: "mainValue") as? String
      detail = aDecoder.decodeObject(forKey: "detail") as? String
    }
  }

}
