//
//  SGLocationManager+rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//
//

import Foundation

import RxSwift

public extension Reactive where Base : SGLocationManager {
  
  /// Fetches the user's current location and fires observable
  /// exactly ones, if successful, and then completes.
  ///
  /// The observable can error out, e.g., if permission was
  /// not granted to the device's location services, or if
  /// no location could be fetched within the alloted time.
  ///
  /// - Parameter seconds: Maximum time to give GPS
  /// - Returns: Observable of user's current location; can error out
  public func fetchCurrentLocation(within seconds: TimeInterval) -> Observable<CLLocation> {
    guard base.isAuthorized() else {
      return tryAuthorization().flatMap { authorized -> Observable<CLLocation> in
        if authorized {
          return self.fetchCurrentLocation(within: seconds)
        } else {
          throw SGLocationManager.LocalizationError.authorizationDenied
        }
      }
    }
    
    return Observable.create { observer in
      self.base.fetchCurrentLocation(within: seconds, success: { (location) in
        observer.onNext(location)
        observer.onCompleted()
      }, failure: { (error) in
        observer.onError(error)
      })
      
      return Disposables.create()
    }
  }
  
  /// Continuously observes the user's current location and fires
  /// observable whenever the user moved more than a minimum
  /// threshold.
  ///
  /// The observable can error out, e.g., if permission was
  /// not granted to the device's location services.
  ///
  /// - Returns: Observable of user's current location; can error out
  public var currentLocation: Observable<CLLocation> {
    
    return Observable.create { subscriber in
      let date = Date()
      let calendar = Calendar.current
      let components = calendar.dateComponents([.minute, .second], from: date)
      let identifier: NSString = "subscription-\(components.minute!)-\(components.second!)" as NSString
      
      if self.base.isAuthorized() {
        self.base.subscribe(toLocationUpdatesId: identifier) { location in
          subscriber.onNext(location)
        }
      } else {
        subscriber.onError(SGLocationManager.LocalizationError.authorizationDenied)
      }
      
      return Disposables.create {
        self.base.unsubscribe(fromLocationUpdates: identifier)
      }
    }
    
  }
  
  
  /// Observes the device's heading
  ///
  /// The observable does not error out and not terminate
  /// by itself.
  ///
  /// - Note: Internally, each subscription creates a new
  /// observable, and a new location manager, so you're
  /// encouraged to share a single subscription.
  public var deviceHeading: Observable<CLHeading> {
    
    return Observable.create { subscriber in
      
      var manager: CLLocationManager! = CLLocationManager()
      var delegate: Delegate! = Delegate()
      manager.startUpdatingHeading()
      manager.delegate = delegate
      
      delegate.onNewHeading = { heading in
        subscriber.onNext(heading)
      }
      
      return Disposables.create {
        manager.stopUpdatingHeading()
        manager = nil
        delegate = nil
      }
    }
    
  }

  
  public func tryAuthorization() -> Observable<Bool> {
    
    if !base.featureIsAvailable() {
      return Observable.error(SGLocationManager.LocalizationError.featureNotAvailable)
    }
    
    switch base.authorizationStatus() {
    case .restricted, .denied:
      return Observable.error(SGLocationManager.LocalizationError.authorizationDenied)
      
    case .authorized:
      return Observable.just(true)
      
    case .notDetermined:
      return Observable.create { observer in
        self.base.ask(forPermission: { success in
          observer.onNext(success)
          observer.onCompleted()
        })
        return Disposables.create()
      }
      
    }
    
  }
  
}


fileprivate class Delegate: NSObject, CLLocationManagerDelegate {
  
  var onNewHeading: ((CLHeading) -> ())? = nil
  
  override init() {
    super.init()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    onNewHeading?(newHeading)
  }
  
}
