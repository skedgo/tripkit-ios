//
//  TKPermissionManager.swift
//  TripKit
//
//  Created by Adrian Schönig on 18/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public enum TKAuthorizationStatus {
  case notDetermined
  case restricted
  case denied
  case authorized
}

public protocol TKPermissionManager {
  
  var openSettingsHandler: (() -> Void)? { get set }

  var authorizationRestrictionsApply: Bool { get }
  
  var featureIsAvailable: Bool { get }
  
  var authorizationStatus: TKAuthorizationStatus { get }
  
  var authorizationAlertText: String { get }
  
  func askForPermission(_ completion: @escaping (Bool) -> Void)
  
}

extension TKPermissionManager {
  
  public var featureIsAvailable: Bool { true }
  
  public var authorizationRestrictionsApply: Bool { true }
  
  public var isAuthorized: Bool {
    guard featureIsAvailable else { return false }
    guard !authorizationRestrictionsApply else { return true }
    return authorizationStatus == .authorized
  }
  
}
