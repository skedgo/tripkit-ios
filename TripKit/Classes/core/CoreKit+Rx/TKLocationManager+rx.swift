//
//  TKLocationManager+rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 20/7/17.
//
//

import Foundation

import RxSwift
import RxCocoa

public extension Reactive where Base : TKLocationManager {
  
  /// Fetches the user's current location and fires observable
  /// exactly ones, if successful, and then completes.
  ///
  /// The observable can error out, e.g., if permission was
  /// not granted to the device's location services, or if
  /// no location could be fetched within the alloted time.
  ///
  /// - Parameter seconds: Maximum time to give GPS
  /// - Returns: Observable of user's current location; can error out
  func fetchCurrentLocation(within seconds: TimeInterval) -> Single<CLLocation> {
    guard base.isAuthorized() else {
      return tryAuthorization().flatMap { authorized -> Single<CLLocation> in
        if authorized {
          return self.fetchCurrentLocation(within: seconds)
        } else {
          throw TKLocationManager.LocalizationError.authorizationDenied
        }
      }
    }
    
    return Single.create { observer in
      self.base.fetchCurrentLocation(within: seconds, success: { (location) in
        observer(.success(location))
      }, failure: { (error) in
        observer(.error(error))
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
  var currentLocation: Observable<CLLocation> {
    
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
        subscriber.onError(TKLocationManager.LocalizationError.authorizationDenied)
      }
      
      return Disposables.create {
        self.base.unsubscribe(fromLocationUpdates: identifier)
      }
    }
    
  }
  
  
#if os(iOS)
  /// Observes the device's heading
  ///
  /// The observable does not error out and not terminate
  /// by itself.
  ///
  /// - Note: Internally, each subscription creates a new
  /// observable, and a new location manager, so you're
  /// encouraged to share a single subscription.
  var deviceHeading: Observable<CLHeading> {
    
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
#endif

  
  func tryAuthorization() -> Single<Bool> {
    
    if !base.featureIsAvailable() {
      return .error(TKLocationManager.LocalizationError.featureNotAvailable)
    }
    
    switch base.authorizationStatus() {
    case .restricted, .denied:
      return .error(TKLocationManager.LocalizationError.authorizationDenied)
      
    case .authorized:
      return .just(true)
      
    case .notDetermined:
      return Single.create { observer in
        self.base.ask(forPermission: { success in
          observer(.success(success))
        })
        return Disposables.create()
      }
      
    }
    
  }
  
}


#if os(iOS)
fileprivate class Delegate: NSObject, CLLocationManagerDelegate {
  
  var onNewHeading: ((CLHeading) -> ())? = nil
  
  override init() {
    super.init()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
    onNewHeading?(newHeading)
  }
  
}
#endif
