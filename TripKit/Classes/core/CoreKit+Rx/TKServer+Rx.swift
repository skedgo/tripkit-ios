//
//  TKServer+Rx.swift
//  TripKit
//
//  Created by Adrian Schoenig on 1/08/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

public enum HTTPMethod: String {
  case POST = "POST"
  case GET = "GET"
  case DELETE = "DELETE"
  case PUT = "PUT"
}

extension Reactive where Base: TKServer {
  public func requireRegion(_ coordinate: CLLocationCoordinate2D) -> Observable<TKRegion> {
    return requireRegions().map {
      TKRegionManager.shared.region(containing: coordinate, coordinate)
    }
  }
  
  public func requireRegion(_ coordinateRegion: MKCoordinateRegion) -> Observable<TKRegion> {
    return requireRegions().map {
        TKRegionManager.shared.region(containing: coordinateRegion)
    }
  }

  public func requireRegions() -> Observable<Void> {
    return Observable.create { subscriber in
      self.base.requireRegions { error in
        guard error == nil else {
          subscriber.onError(error!)
          return
        }
        
        subscriber.onNext(())
        subscriber.onCompleted()
      }
      
      return Disposables.create()
    }
    
  }

  /// Hit a SkedGo endpoint, using a variety of options
  ///
  /// - parameter method: Duh
  /// - parameter path: The endpoint, e.g., `routing.json`
  /// - parameter parameters: The parameters which will either be send in the query (for GET) or as the JSON body (for POST and alike)
  /// - parameter headers: Additional headers to add to the request
  /// - parameter region: The region for which to hit a server. In most cases, you want to set this as not every SkedGo server has data for every region.
  /// - parameter repeatHandler: Implement and return a non-negative time interval from this handler to fire the Observable again, or `nil` to stop firing.
  /// - returns: An observable with the status code, headers and data from hitting the endpoint, all status and data will be the same as the last call to the `repeatHandler`.
  public func hit(
    _ method: HTTPMethod,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil,
    repeatHandler: ((Int, Data?) -> (TimeInterval?))? = nil
    ) -> Observable<(Int, [String: Any], Data?)>
  {
    
    return Observable.create { subscriber in
      let stopper = Stopper()
      
      self.hitSkedGo(
        method: method,
        path: path,
        parameters: parameters,
        headers: headers,
        region: region,
        repeatHandler: { code, responseHeaders, data in
          if stopper.stop {
            // we got discarded
            return nil
          }
          
          let hitAgain: TimeInterval?
          if let repeatHandler = repeatHandler {
            hitAgain = repeatHandler(code, data)
          } else {
            hitAgain = nil
          }
          
          subscriber.onNext((code, responseHeaders, data))
          if hitAgain == nil {
            subscriber.onCompleted()
          }
          return hitAgain
          
        }, errorHandler: { error in
          subscriber.onError(error)
        }
      )
      
      return Disposables.create() {
        stopper.stop = true
      }
    }
  }
  
  private func hitSkedGo(method: HTTPMethod, path: String, parameters: [String: Any] = [:], headers: [String: String] = [:], region: TKRegion? = nil, repeatHandler: @escaping (Int, [String: Any], Data?) -> (TimeInterval?), errorHandler: @escaping (Error) -> ()) {

    self.base.hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: false,
      success: { code, responseHeaders, response, data in
        
        let hitAgain = repeatHandler(code, responseHeaders, data)
        if let seconds = hitAgain, seconds > 0 {
          let queue = DispatchQueue.global(qos: .userInitiated)
          queue.asyncAfter(deadline: DispatchTime.now() + seconds) {
            self.hitSkedGo(
              method: method,
              path: path,
              parameters: parameters,
              headers: headers,
              region: region,
              repeatHandler: repeatHandler,
              errorHandler: errorHandler
            )
          }
          
        }
        
      },
      failure: errorHandler)
  }
}

private class Stopper {
  var stop = false
}
