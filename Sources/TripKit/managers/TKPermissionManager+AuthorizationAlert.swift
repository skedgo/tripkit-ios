//
//  TKPermissionManager+AuthorizationAlert.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit

extension TKPermissionManager {
  
  public func tryAuthorization(sender: Any? = nil, in controller: UIViewController, completion: @escaping (Bool) -> Void) {
    guard featureIsAvailable else {
      completion(false)
      return
    }
    
    guard !isAuthorized else {
      completion(true)
      return
    }
    
    switch authorizationStatus {
    case .restricted,
         .denied:
      showAuthorizationAlert(sender: sender, in: controller)
      completion(false)
      
    case .notDetermined:
      askForPermission(completion)
      
    case .authorized:
      assert(false, "How did we end up here?")
      completion(true)
    }
  }
  
  
  public func showAuthorizationAlert(sender: Any? = nil, in controller: UIViewController) {
    guard authorizationRestrictionsApply else { return }
    
    let message: String
    switch authorizationStatus {
    case .denied:
      message = authorizationAlertText
    case .restricted:
      message = Loc.AuthorizationNeededDescription
    case .notDetermined,
         .authorized:
      return
    }
    
    let alert = UIAlertController(title: Loc.AuthorizationNeeded, message: message, preferredStyle: .alert)
    
    if let handler = openSettingsHandler {
      alert.addAction(.init(title: Loc.Cancel, style: .cancel))
      alert.addAction(.init(title: Loc.OpenSettings, style: .default) { _ in
        handler()
      })
    } else {
      alert.addAction(.init(title: Loc.OK, style: .default))
    }
    
    DispatchQueue.main.async {
      controller.present(alert, animated: true)
    }
  }
  
}

#endif
