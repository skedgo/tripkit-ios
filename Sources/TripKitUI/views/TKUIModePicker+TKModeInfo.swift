//
//  TKUIModePicker+TKModeInfo.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

extension TKModeInfo: TKUIModePickerItem {
  public var imageURLIsTemplate: Bool { remoteImageIsTemplate }
  public var imageTextRepresentation: String { alt }
  public var imageURLIsBranding: Bool { remoteImageIsBranding }
}

extension TKModeInfo: @retroactive Comparable {
  public static func < (lhs: TKModeInfo, rhs: TKModeInfo) -> Bool {
    if let leftId = lhs.identifier, let rightId = rhs.identifier {
      return leftId < rightId
    } else {
      return lhs.identifier != nil
    }
  }
}
