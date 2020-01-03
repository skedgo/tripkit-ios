//
//  TKMiniInstruction.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

class TKMiniInstruction: NSObject, Codable, NSSecureCoding {
  let instruction: String
  let detail: String?
  
  private enum CodingKeys: String, CodingKey {
    case instruction
    case detail = "description"
  }
  
  static func instruction(for json: [String: Any]?) -> TKMiniInstruction? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(TKMiniInstruction.self, withJSONObject: json)
  }
  
  // MARK: NSSecure coding
  
  @objc
  static var supportsSecureCoding: Bool { return true }
  
  @objc(encodeWithCoder:)
  func encode(with aCoder: NSCoder) {
    guard let data = try? JSONEncoder().encode(self) else { return }
    aCoder.encode(data)
  }
  
  @objc
  required init?(coder aDecoder: NSCoder) {
    if let data = aDecoder.decodeData() {
      // The new way
      do {
        let decoded = try JSONDecoder().decode(TKMiniInstruction.self, from: data)
        instruction = decoded.instruction
        detail = decoded.detail
      } catch {
        assertionFailure("Couldn't decode due to: \(error)")
        return nil
      }
      
    } else {
      // For backwards compatibility
      instruction = (aDecoder.decodeObject(forKey: "instruction") as? String) ?? ""
      detail = aDecoder.decodeObject(forKey: "detail") as? String
    }
  }

}
