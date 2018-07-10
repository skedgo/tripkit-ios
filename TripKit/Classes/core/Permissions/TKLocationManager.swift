//
//  TKLocationManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/7/17.
//
//

import Foundation

public extension TKLocationManager {
  
  public enum LocalizationError: Error {
    
    case featureNotAvailable
    case authorizationDenied
    
  }
  
  public static let shared = TKLocationManager.__sharedInstance()

  public var currentLocation: MKAnnotation {
    return __currentLocationPlaceholder()
  }
  
}


// TKPermissionManager overrides

extension TKLocationManager {
  
  open override func featureIsAvailable() -> Bool {
    return true
  }
  
  open override func authorizationRestrictionsApply() -> Bool {
    return true
  }
  
  open override func authorizationStatus() -> TKAuthorizationStatus {
    guard CLLocationManager.locationServicesEnabled() else {
      return .denied
    }
    
    guard authorizationRestrictionsApply() else {
      return .authorized
    }
    
    switch CLLocationManager.authorizationStatus() {
    case .authorizedAlways, .authorizedWhenInUse: return .authorized
    case .denied: return .denied
    case .restricted: return .restricted
    case .notDetermined: return .notDetermined
    }
  }
  
  open override func authorizationAlertText() -> String {
    return NSLocalizedString("Location services are required to use this feature. Please go to the Settings app > Privacy > Location Services, make sure they are turned on and authorise this app.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Location iOS authorisation needed text")
  }
  
  
}
