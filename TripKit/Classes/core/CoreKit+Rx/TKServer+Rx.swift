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

public extension TKServer {

  enum HTTPMethod: String {
    case POST = "POST"
    case GET = "GET"
    case DELETE = "DELETE"
    case PUT = "PUT"
  }

  enum RepeatHandler {
    case repeatIn(TimeInterval)
    case repeatWithNewParameters(TimeInterval, [String: Any])
  }

  static func buildRequest(
    _ method: TKServer.HTTPMethod,
    path: String,
    parameters: [String: Any] = [:],
    region: TKRegion? = nil
  ) -> URLRequest {
    return shared.buildSkedGoRequest(withMethod: method.rawValue, path: path, parameters: parameters, region: region)
  }
}

extension Reactive where Base: TKServer {
  public func requireRegion(_ coordinate: CLLocationCoordinate2D) -> Single<TKRegion> {
    return requireRegions()
      .map {
        TKRegionManager.shared.region(containing: coordinate, coordinate)
      }
  }
  
  public func requireRegion(_ coordinateRegion: MKCoordinateRegion) -> Single<TKRegion> {
    return requireRegions()
      .map {
        TKRegionManager.shared.region(containing: coordinateRegion)
      }
  }

  public func requireRegions() -> Single<Void> {
    return Single.create { subscriber in
      self.base.requireRegions { error in
        guard error == nil else {
          subscriber(.error(error!))
          return
        }
        subscriber(.success(()))
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
  /// - returns: An observable with the status code, headers and data from hitting the endpoint, all status and data will be the same as the last call to the `repeatHandler`.
  public func hit(
    _ method: TKServer.HTTPMethod,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil
    ) -> Single<(Int, [String: Any], Data?)>
  {
    return stream(method, path: path, parameters: parameters, headers: headers, region: region, repeatHandler: nil)
      .asSingle()
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
  public func stream(
    _ method: TKServer.HTTPMethod,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil,
    repeatHandler: ((Int, Data?) -> TKServer.RepeatHandler?)? = nil
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
          
          let hitAgain: TKServer.RepeatHandler?
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
  
  private func hitSkedGo(
      method: TKServer.HTTPMethod,
      path: String,
      parameters: [String: Any] = [:],
      headers: [String: String] = [:],
      region: TKRegion? = nil,
      repeatHandler: @escaping (Int, [String: Any], Data?) -> TKServer.RepeatHandler?,
      errorHandler: @escaping (Error) -> ()
    ) {

    self.base.hitSkedGo(
      withMethod: method.rawValue,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: false,
      success: { code, responseHeaders, response, data in
        if let hitAgain = repeatHandler(code, responseHeaders, data) {
          // These are the variables that control how a request is repeated
          // 1. retryIn: tells us when we can try again, in seconds.
          // 2. newParameters: tells us when we do retry, what parameters to use. This
          //    may be different from the original request.
          let retryIn: TimeInterval
          let newParameters: [String : Any]
          
          switch hitAgain {
          case .repeatIn(let seconds):
            retryIn = seconds
            newParameters = parameters
          case .repeatWithNewParameters(let seconds, let paras):
            retryIn = seconds
            newParameters = paras
          }
          
          if retryIn > 0 {
            let queue = DispatchQueue.global(qos: .userInitiated)
            queue.asyncAfter(deadline: DispatchTime.now() + retryIn) {
              self.hitSkedGo(
                method: method,
                path: path,
                parameters: newParameters,
                headers: headers,
                region: region,
                repeatHandler: repeatHandler,
                errorHandler: errorHandler
              )
            }
          }
        }
      },
      failure: errorHandler)
  }
}

private class Stopper {
  var stop = false
}
