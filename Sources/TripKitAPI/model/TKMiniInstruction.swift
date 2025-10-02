//
//  TKMiniInstruction.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public final class TKMiniInstruction: NSObject, Codable, NSSecureCoding, Sendable {
  public let instruction: String
  public let detail: String?
  
  private enum CodingKeys: String, CodingKey {
    case instruction
    case detail = "description"
  }
  
  // MARK: NSSecure coding
  
  public static var supportsSecureCoding: Bool { return true }
  
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(instruction, forKey: "instruction")
    aCoder.encode(detail, forKey: "detail")
  }
  
  public required init?(coder aDecoder: NSCoder) {
    guard let instruction = aDecoder.decodeObject(of: NSString.self, forKey: "instruction") as String? else {
      assertionFailure()
      return nil
    }
    self.instruction = instruction
    detail = aDecoder.decodeObject(of: NSString.self, forKey: "detail") as String?
  }

}
