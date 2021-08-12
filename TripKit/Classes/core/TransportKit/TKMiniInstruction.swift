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
  
  // MARK: NSSecure coding
  
  @objc
  static var supportsSecureCoding: Bool { return true }
  
  @objc(encodeWithCoder:)
  func encode(with aCoder: NSCoder) {
    aCoder.encode(instruction, forKey: "instruction")
    aCoder.encode(detail, forKey: "detail")
  }
  
  @objc
  required init?(coder aDecoder: NSCoder) {
    guard let instruction = aDecoder.decodeObject(of: NSString.self, forKey: "instruction") as String? else {
      assertionFailure()
      return nil
    }
    self.instruction = instruction
    detail = aDecoder.decodeObject(of: NSString.self, forKey: "detail") as String?
  }

}
