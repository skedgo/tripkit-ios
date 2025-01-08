//
//  TKModeInfo+TripKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 19/11/2024.
//

import Foundation

import TripKitAPI

@available(*, unavailable, renamed: "TKModeInfo")
public typealias ModeInfo = TKModeInfo

extension TKModeInfo {
  
  public static var unknown: TKModeInfo = modeInfo(for: ["alt": "unknown"])!
  
  /// Determines if the saved mode is enabled or disabled.
  @objc public var isEnabled: Bool {
    let disabledSharedVehicleModes = TKSettings.disabledSharedVehicleModes
    guard let encoded = try? JSONEncoder().encode(self)
    else {
      return true
    }
    return !disabledSharedVehicleModes.contains(encoded)
  }
  
  @objc(modeInfoForDictionary:)
  public class func modeInfo(for json: [String: Any]?) -> TKModeInfo? {
    guard let json = json else { return nil }
    let decoder = JSONDecoder()
    return try? decoder.decode(TKModeInfo.self, withJSONObject: json)
  }
  
}
