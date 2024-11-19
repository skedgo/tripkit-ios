//
//  TKLocationManager.swift
//  TripKit
//
//  Created by Adrian Schoenig on 14/7/17.
//
//

import Foundation

#if canImport(MapKit)

import Combine
import MapKit

public class TKLocationManager: NSObject, TKPermissionManager {
  
  public enum LocalizationError: Error {
    case featureNotAvailable
    case authorizationDenied
  }
  
  public static let shared = TKLocationManager()
  
  public private(set) var lastKnownUserLocation: CLLocation? {
    didSet {
      // is the new one good enough to tell everyone about it?
      guard let lastKnownUserLocation, lastKnownUserLocation.isInTheLast(60), lastKnownUserLocation.horizontalAccuracy < 500 else {
        return
      }
      
      tellAllFetchersNow()
      tellAllSubscribers(lastKnownUserLocation)
      considerStopping()
    }
  }
  
  lazy var coreLocationManager: CLLocationManager = {
    let manager = CLLocationManager()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    manager.distanceFilter = 250
    return manager
  }()
  
  public lazy var currentLocation: MKAnnotation = {
    let annotation = MKPointAnnotation()
    annotation.coordinate = .invalid
    annotation.title = Loc.CurrentLocation
    return annotation
  }()
  
  private var fetchTimers = Set<Timer>()
  private var subscriberBlocks: [AnyHashable: (CLLocation) -> Void] = [:]
  private var permissionBlock: ((Bool) -> Void)? = nil
  private var cancellables = Set<AnyCancellable>()

  public var openSettingsHandler: (() -> Void)? = nil
  
  private override init() {
    super.init()
    
#if canImport(UIKit)
    NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
      .sink { [weak self] _ in
        guard let self else { return }
        for timer in self.fetchTimers {
          timer.invalidate()
        }
        // keep them in there, so we can do something with them when we get back
      }
      .store(in: &cancellables)

    NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
      .sink { [weak self] _ in
        self?.tellAllFetchersNow()
      }
      .store(in: &cancellables)
#endif
  }

  public func annotationIsCurrentLocation(_ annotation: MKAnnotation, orCloseEnough: Bool) -> Bool {
    if annotation === currentLocation {
      return true
    }
    if annotation is MKUserLocation {
      return true
    }
    
    guard orCloseEnough, let lastKnownUserLocation else {
      return false
    }
    
    return lastKnownUserLocation.distance(from: .init(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)) < 250
  }
  
}



// MARK: - Fetch

extension TKLocationManager {
  
  private func tellAllFetchersNow() {
    for timer in fetchTimers {
      timer.fire()
    }
    fetchTimers.removeAll()
  }
  
  public func fetch(within interval: TimeInterval, completion: @escaping (Result<CLLocation, Error>) -> Void) {
    // Yes, we even do this when not authorized, as it'll trigger asking
    // for access.
    
    guard interval > 0 else {
      return tellFetcherNow(completion)
    }
    
    if let lastKnownUserLocation, lastKnownUserLocation.isInTheLast(90) {
      return tellFetcherNow(completion)
    }
    
    // make sure we are updating
    coreLocationManager.startUpdatingLocation()
    
    fetchTimers.insert(.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] timer in
      guard let self, self.fetchTimers.contains(timer) else {
        return // we called success block already
      }
      self.fetchTimers.remove(timer)
      self.tellFetcherNow(completion)
      self.considerStopping()
    })
  }
  
  private func tellFetcherNow(_ completion: @escaping (Result<CLLocation, Error>) -> Void) {
    if let lastKnownUserLocation {
      completion(.success(lastKnownUserLocation))
    } else {
      completion(.failure(NSError(domain: "com.skedgo.TripKit", code: 198364, userInfo: [
        NSLocalizedDescriptionKey: Loc.CouldNotFetchCurrentLocationTitle,
        NSLocalizedRecoverySuggestionErrorKey: Loc.CouldNotFetchCurrentLocationRecovery,
      ])))
    }
  }
  
}

// MARK: - Subscribe

extension TKLocationManager {
  
  private func tellAllSubscribers(_ location: CLLocation) {
    for subscriber in subscriberBlocks.values {
      subscriber(location)
    }
  }
  
  private func considerStopping() {
    if subscriberBlocks.isEmpty && fetchTimers.isEmpty {
      coreLocationManager.stopUpdatingLocation()
    }
  }

  /// Subscripes to location updates and trigger the update block whenever the location changes enough.
  ///
  /// - Parameters:
  ///   - id: A token to use as an subscription identifier
  ///   - onUpdate: Called on each location fix. If there's a location fix already, it'll trigger the update before returning!
  public func subscribe(id: AnyHashable, onUpdate: @escaping (CLLocation) -> Void) {
    guard isAuthorized else { return }
    
    subscriberBlocks[id] = onUpdate
    
    if let lastKnownUserLocation {
      onUpdate(lastKnownUserLocation)
    }
    
    // make sure we are updating
    coreLocationManager.startUpdatingLocation()
  }
  
  public func unsubscribe(id: AnyHashable) {
    subscriberBlocks.removeValue(forKey: id)
    considerStopping()
  }

}

// MARK: - TKPermissionManager overrides

extension TKLocationManager {
  
  public func askForPermission(_ completion: @escaping (Bool) -> Void) {
    self.permissionBlock = completion
#if os(macOS)
    coreLocationManager.startUpdatingLocation()
#else
    coreLocationManager.requestWhenInUseAuthorization()
#endif
  }
  
  public var featureIsAvailable: Bool {
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
  
  public var authorizationStatus: TKAuthorizationStatus {
    guard authorizationRestrictionsApply else {
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
  
  public var authorizationAlertText: String {
    return Loc.LocalizationPermissionsMissing
  }
  
}

// MARK: - CLLocationManagerDelegate

extension TKLocationManager: CLLocationManagerDelegate {
  
  private func updateForStaus(_ status: CLAuthorizationStatus) {
    guard status != .notDetermined, let permissionBlock else {
      // ignore this status as it doesn't tell
      // us anything useful here.
      return
    }
    
    let enabled: Bool
    switch status {
#if !os(macOS)
    case .authorizedWhenInUse:
      enabled = true
#endif
    case .authorizedAlways:
      enabled = true
    case .notDetermined, .restricted, .denied:
      enabled = false
    @unknown default:
      enabled = false
    }
    
    if enabled {
      coreLocationManager.startUpdatingLocation()
    }
    permissionBlock(enabled)
    self.permissionBlock = nil
  }
  
  @available(macOS 11.0, iOS 14.0, *)
  public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    updateForStaus(manager.authorizationStatus)
  }
  
  public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    updateForStaus(status)
  }
  
  public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let latest = locations.last else { return }
    
    // can we ignore the new location?
    // we do so if the one is still recent, new one is not more accurate and too close to old => ignore
    if let lastKnownUserLocation, lastKnownUserLocation.isInTheLast(60), latest.distance(from: lastKnownUserLocation) < manager.distanceFilter, latest.horizontalAccuracy > lastKnownUserLocation.horizontalAccuracy {
      return
    }
    
    // go ahead with the new
    // note that this can trigger informing everyone
    lastKnownUserLocation = latest
  }
  
}

fileprivate extension CLLocation {
  func isInTheLast(_ seconds: TimeInterval) -> Bool {
    abs(timestamp.timeIntervalSinceNow) <= seconds
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

#endif
