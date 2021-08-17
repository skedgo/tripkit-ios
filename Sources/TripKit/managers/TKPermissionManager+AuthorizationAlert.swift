//
//  TKPermissionManager+AuthorizationAlert.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit

extension TKPermissionManager {
  
  public func tryAuthorization(sender: Any? = nil, in controller: UIViewController, completion: @escaping (Bool) -> Void) {
    guard featureIsAvailable() else {
      completion(false)
      return
    }
    
    guard !isAuthorized() else {
      completion(true)
      return
    }
    
    switch authorizationStatus() {
    case .restricted,
         .denied:
      showAuthorizationAlert(sender: sender, in: controller)
      completion(false)
      
    case .notDetermined:
      ask(forPermission: completion)
      
    case .authorized:
      assert(false, "How did we end up here?")
      completion(true)
    }
  }
  
  @objc(showAuthorizationAlertForSender:inViewController:)
  public func showAuthorizationAlert(sender: Any? = nil, in controller: UIViewController) {
    guard authorizationRestrictionsApply() else { return }
    
    let message: String
    switch authorizationStatus() {
    case .denied:
      message = authorizationAlertText()
    case .restricted:
      message = NSLocalizedString("Access to this feature has been restricted for your device. Please check the Settings app > General > Restrictions or ask your device provider.", tableName: "Shared", bundle: .tripKit, comment: "Authorization restricted alert message")
    case .notDetermined,
         .authorized:
      return
    }
    
    let alert = TKActions(title: NSLocalizedString("Authorisation needed", tableName: "Shared", bundle: .tripKit, comment: "Authorisation needed title"))
    alert.message = message
    
    if let handler = openSettingsHandler {
      alert.hasCancel = true
      alert.addAction(NSLocalizedString("Open Settings", tableName: "Shared", bundle: .tripKit, comment: "Button that goes to the Setting's app"), handler: handler)
    } else {
      alert.hasCancel = false
      alert.addAction(Loc.OK, handler: nil)
    }
    
    DispatchQueue.main.async {
      alert.showForSender(sender, in: controller)
    }
  }
  
}

#endif