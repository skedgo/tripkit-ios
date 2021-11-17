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
    return NSLocalizedString("Location services are required to use this feature. Please go to the Settings app > Privacy > Location Services, make sure they are turned on and authorise this app.", tableName: "Shared", bundle: .tripKit, comment: "Location iOS authorisation needed text")
  }
  
  
}
