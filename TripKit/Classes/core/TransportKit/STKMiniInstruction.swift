//
//  STKMiniInstruction.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public struct STKMiniInstruction: Codable, Equatable {
  public let instruction: String
  public let mainValue: String?
  public let detail: String?
  
  private enum CodingKeys: String, CodingKey {
    case instruction
    case mainValue
    case detail = "description"
  }
  
  public static func instruction(for json: [String: Any]?) -> STKMiniInstruction? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(STKMiniInstruction.self, withJSONObject: json)
  }

}
