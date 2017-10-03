//
//  STKModeHelper.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 5/1/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class STKModeHelper : NSObject {
  
  private override init() {
    super.init()
  }
  
  /// Does a special modal intersection, which considers hierarchy of modes
  ///
  /// This intersects if there's a mode in `secondary` that's a sub-mode of
  /// any mode in `primary`. E.g., `me_car-s_GOG` is a submode of `me_car-s`,
  /// but not of `me_car`.
  ///
  /// - Parameters:
  ///   - primary: Modes that can be shorter
  ///   - secondary: Modes that can be longer
  /// - Returns: If any mode in secondary is in primary or a submode of any
  ///            mode in primary
  @objc(modes:contain:)
  public static func modesContain(_ primary: Set<String>, _ secondary: Set<String>) -> Bool {
    
    // quick full matches
    if primary.intersection(secondary).count > 0 {
      return true
    }
    
    // slower partial matches, where secondaries have two "_"
    for longie in secondary {
      for shortie in primary {
        if let range = longie.range(of: shortie) {
          let remainder = longie.replacingCharacters(in: range, with: "")
          if let first = remainder.first, first == "_" {
            return true
          }
        }
      }
    }
    return false
  }

}
