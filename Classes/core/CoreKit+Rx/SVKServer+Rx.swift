//
//  SVKServer+Rx.swift
//  SGSkedGoKit
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

extension Reactive where Base: SVKServer {
  public func requireRegion(_ coordinate: CLLocationCoordinate2D) -> Observable<SVKRegion> {
    return requireRegions().map {
        SVKRegionManager.shared.region(coordinate, coordinate)
    }
  }
  
  public func requireRegion(_ coordinateRegion: MKCoordinateRegion) -> Observable<SVKRegion> {
    return requireRegions().map {
        SVKRegionManager.shared.region(for: coordinateRegion)
    }
  }

  public func requireRegions() -> Observable<Void> {
    return Observable.create { subscriber in
      self.base.requireRegions { error in
        guard error == nil else {
          subscriber.onError(error!)
          return
        }
        
        subscriber.onNext()
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
  /// - parameter region: The region for which to hit a server. In most cases, you want to set this as not every SkedGo server has data for every region.
  /// - parameter repeatHandler: Implement and return a non-negative time interval from this handler to fire the Observable again, or `nil` to stop firing.
  /// - returns: An observable with the status code and JSON from hitting the endpoint, both parameters will be the same as the last call to the `repeatHandler`.
  public func hit(
    _ method: HTTPMethod,
    path: String,
    parameters: [String: Any] = [:],
    region: SVKRegion? = nil,
    repeatHandler: ((Int, Any?) -> (TimeInterval?))? = nil
  ) -> Observable<(Int, Any?)>
  {
    
    return Observable.create { subscriber in
      let stopper = Stopper()
      
      self.hitSkedGo(
        method: method,
        path: path,
        parameters: parameters,
        region: region,
        repeatHandler: { code, json in
          if stopper.stop {
            // we got discarded
            return nil
          }
          
          let hitAgain: TimeInterval?
          if let repeatHandler = repeatHandler {
            hitAgain = repeatHandler(code, json)
          } else {
            hitAgain = nil
          }
          
          subscriber.onNext(code, json)
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
  
  private func hitSkedGo(method: HTTPMethod, path: String, parameters: [String: Any] = [:], region: SVKRegion? = nil, repeatHandler: @escaping (Int, Any?) -> (TimeInterval?), errorHandler: @escaping (Error) -> ()) {

    self.base.hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      callbackOnMain: false,
      success: { code, response in
        
        let hitAgain = repeatHandler(code, response)
        if let seconds = hitAgain, seconds > 0 {
          let queue = DispatchQueue.global(qos: .userInitiated)
          queue.asyncAfter(deadline: DispatchTime.now() + seconds) {
            self.hitSkedGo(
              method: method,
              path: path,
              parameters: parameters,
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
