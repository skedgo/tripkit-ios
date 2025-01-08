//
//  TKOneOffLocationManager.swift
//  TripKit
//
//  Created by Adrian Schönig on 10/5/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if canImport(CoreLocation)

import CoreLocation

@available(iOS 14.0, macOS 11.0,  *)
public class TKOneOffLocationManager: NSObject {
  
  public override init() {
    locationManager = .init()
    hasAccess = false
    
    super.init()
    
    locationManager.delegate = self
  }
  
  public enum LocationFetchError: Error {
    case accessNotProvided
    
    /// Happens if you stop monitoring before a location could be found
    case noLocationFetchedInTime
    
    /// Happens if no accurate fix could be found, best location attached
    case locationInaccurate(CLLocation)
  }
  
  private let locationManager: CLLocationManager
  
  // MARK: - Access
  
  /// Whether user has granted any kind of access to the device's location, when-in-use or always
  @Published public var hasAccess: Bool
  
  private var askHandler: (Bool) -> Void = { _ in }

  /// Whether it's possible to bring up the system prompt to ask for access to the device's location
  public var canAsk: Bool {
    switch locationManager.authorizationStatus {
    case .notDetermined:
      return true
    case .authorizedAlways, .authorizedWhenInUse, .denied, .restricted:
      return false
    @unknown default:
      return false
    }
  }
  
  private func updateAccess() {
    switch locationManager.authorizationStatus {
    case .authorizedAlways:
      hasAccess = true
      // Note: We do NOT update `enableInBackground` here, as that's the user's
      // setting, i.e., they might not want to have it enabled even though the
      // app has permissions.
    case .authorizedWhenInUse:
      hasAccess = true
    case .denied, .notDetermined, .restricted:
      hasAccess = false
    @unknown default:
      hasAccess = false
    }
  }
  
  public func ask(forBackground: Bool = false, _ handler: @escaping (Bool) -> Void = { _ in }) {
    if forBackground {
      if locationManager.authorizationStatus == .notDetermined {
        // Need to *first* ask for when in use, and only for always if that
        // is granted.
        ask(forBackground: false) { success in
          if success {
            self.ask(forBackground: true, handler)
          } else {
            handler(false)
          }
        }
      } else {
        self.askHandler = handler
        locationManager.requestAlwaysAuthorization()
      }
    } else {
      self.askHandler = handler
      locationManager.requestWhenInUseAuthorization()
    }
  }
  
  @discardableResult
  public func ask(forBackground: Bool = false) async -> Bool {
    return await withCheckedContinuation { continuation in
      ask(forBackground: forBackground) { result in
        continuation.resume(returning: result)
      }
    }
  }
  
  // MARK: - Location fetching
  
  @Published public var currentLocation: CLLocation?

  private var withNextLocation: [(Result<CLLocation, Error>) -> Void] = []
  
  private var fetchTimer: Timer?
  
  public func fetchCurrentLocation() async throws -> CLLocation {
    guard hasAccess else {
      throw LocationFetchError.accessNotProvided
    }
    
    let desiredAccuracy = kCLLocationAccuracyHundredMeters
    if let currentLocation = currentLocation,
        currentLocation.timestamp.timeIntervalSinceNow > -10,
        currentLocation.horizontalAccuracy <= desiredAccuracy {
      // We have a current location and it's less than 10 seconds old. Just use it
      return currentLocation
    }
    
    let originalAccuracy = locationManager.desiredAccuracy
    locationManager.desiredAccuracy = desiredAccuracy
    locationManager.requestLocation()
    
    fetchTimer = .scheduledTimer(withTimeInterval: 10, repeats: false) { [unowned self] _ in
      self.notify(.failure(LocationFetchError.noLocationFetchedInTime))
    }
    
    return try await withCheckedThrowingContinuation { continuation in
      withNextLocation.append({ [unowned self] result in
        self.locationManager.desiredAccuracy = originalAccuracy
        continuation.resume(with: result)
      })
    }
  }
  
  private func notify(_ result: Result<CLLocation, Error>) {
    fetchTimer?.invalidate()
    fetchTimer = nil
    
    withNextLocation.forEach {
      $0(result)
    }
    withNextLocation = []
  }
  
}

// MARK: - CLLocationManagerDelegate

@available(iOS 14.0, macOS 11.0, *)
extension TKOneOffLocationManager: CLLocationManagerDelegate {
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let latest = locations.last else { return assertionFailure() }
    
    guard let latestAccurate = locations
      .filter({ $0.horizontalAccuracy <= manager.desiredAccuracy })
      .last
    else {
      notify(.failure(LocationFetchError.locationInaccurate(latest)))
      return
    }

    self.currentLocation = latestAccurate
    
    notify(.success(latestAccurate))
  }
  
  public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    notify(.failure(error))
  }
  
  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if case .notDetermined = manager.authorizationStatus {
      return // happens immediately when asking for access
    }
    
    updateAccess()
    askHandler(hasAccess)
    askHandler = { _ in }
    
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse:
      manager.requestLocation()
    case .denied, .notDetermined, .restricted:
      return
    @unknown default:
      return
    }
  }
  
}

#endif
