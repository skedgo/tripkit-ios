//
//  TKRouter.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKRouter {
  /// :nodoc:
  @objc(mergeQueryItems:)
  public static func merge(items: Set<URLQueryItem>) -> [String: Any] {
    return Dictionary(grouping: items, by: \.name)
      .compactMapValues { list -> Any? in
        if list.count == 1, let first = list.first {
          return first.value
        } else {
          return list.map(\.value)
        }
      }
  }
}

