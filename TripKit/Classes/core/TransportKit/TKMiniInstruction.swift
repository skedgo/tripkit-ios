//
//  TKMiniInstruction.swift
//  TripKit
//
//  Created by Adrian Schönig on 05.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

public struct TKMiniInstruction: Codable, Equatable {
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

}
