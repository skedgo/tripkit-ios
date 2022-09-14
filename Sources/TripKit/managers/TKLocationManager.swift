//
//  TKLocationManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/7/17.
//
//

import Foundation
import MapKit

public extension TKLocationManager {
  
  enum LocalizationError: Error {
    
    case featureNotAvailable
    case authorizationDenied
    
  }
  
  static let shared = TKLocationManager.__sharedInstance()

  var currentLocation: MKAnnotation {
    return __currentLocationPlaceholder()
  }
  
}

extension TKLocationManager.LocalizationError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .authorizationDenied:
      return Loc.LocalizationPermissionsMissing
    case .featureNotAvailable:
      return nil
    }
  }
}

 
// TKPermissionManager overrides

extension TKLocationManager {
  
  open override func featureIsAvailable() -> Bool {
    if Bundle.main.infoDictionary?.keys.contains("NSLocationWhenInUseUsageDescription") == true {
      return true
    }
    
    #if DEBUG
    // Assume available, when running tests
    return ProcessInfo().environment.keys.contains("XCTestSessionIdentifier")
    #else
    return false
    #endif
  }
  
  open override func authorizationRestrictionsApply() -> Bool {
    return true
  }
  
  open override func authorizationStatus() -> TKAuthorizationStatus {
    guard authorizationRestrictionsApply() else {
      return .authorized
    }
    
    let status: CLAuthorizationStatus
    if #available(macOS 11.0, iOS 14.0, *) {
      status = CLLocationManager().authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }
    
    switch status {
    case .authorizedAlways, .authorizedWhenInUse: return .authorized
    case .denied: return .denied
    case .restricted: return .restricted
    case .notDetermined: return .notDetermined
    @unknown default:
      assertionFailure("Unexpected case, treating as not determined.")
      return .notDetermined
    }
  }
  
  open override func authorizationAlertText() -> String {
    return Loc.LocalizationPermissionsMissing
  }
  
}
