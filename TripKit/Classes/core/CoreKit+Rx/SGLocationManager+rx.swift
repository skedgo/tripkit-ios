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
