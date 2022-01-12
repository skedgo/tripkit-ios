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

import TripKit

extension Reactive where Base: TKRegionManager {
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
      self.base.requireRegions(completion: subscriber)
      return Disposables.create()
    }
    
  }
}


extension Reactive where Base: TKServer {
  
  public static func hit(_ method: TKServer.HTTPMethod = .GET, url: URL, parameters: [String: Any]? = nil) -> Single<(Int, [String: Any], Data)> {
    return Single.create { single in
      Base.hit(method, url: url, parameters: parameters) { code, responseHeader, result in
        single(result.map { (code, responseHeader, $0) })
      }
      return Disposables.create()
    }
  }

  public static func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: TKServer.HTTPMethod = .GET,
    url: URL,
    parameters: [String: Any] = [:]
    ) -> Single<(Int, [String: Any], Model)>
  {
    Single.create { subscriber in
      TKServer.hit(type, url: url, parameters: parameters) { status, headers, result in
        subscriber(result.map { (status, headers, $0) })
      }
      return Disposables.create()
    }
  }
  
  public func hit(
    _ method: TKServer.HTTPMethod = .GET,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil
    ) -> Single<(Int?, [String: Any], Data?)>
  {
    Single.create { subscriber in
      base.hit(method, path: path, parameters: parameters, headers: headers, region: region
      ) { status, headers, result in
        do {
          let data = try result.get()
          subscriber(.success((status, headers, data)))
        } catch {
          if let serverError = error as? TKServer.ServerError, serverError == .noData {
            subscriber(.success((status, headers, nil)))
          } else {
            subscriber(.failure(error))
          }
        }
      }
      return Disposables.create()
    }
  }
  
  public func stream(
    _ method: TKServer.HTTPMethod = .GET,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil,
    repeatHandler: ((Int?, Data?) -> TKServer.RepeatHandler?)? = nil
    ) -> Observable<(Int?, [String: Any], Data?)>
  {
    
    return Observable.create { subscriber in
      let stopper = Stopper()
      
      self.hit(
        method,
        path: path,
        parameters: parameters,
        headers: headers,
        region: region,
        repeatHandler: { code, responseHeaders, result in
          if stopper.stop {
            // we got discarded
            return nil
          }
          
          let hitAgain: TKServer.RepeatHandler?
          let model = try? result.get()
          if let repeatHandler = repeatHandler {
            hitAgain = repeatHandler(code, model)
          } else {
            hitAgain = nil
          }
          
          subscriber.onNext((code, responseHeaders, model))
          
          if hitAgain == nil {
            subscriber.onCompleted()
          }
          
          return hitAgain
        }
      )
      
      return Disposables.create() {
        stopper.stop = true
      }
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
  public func hit<Model: Decodable>(
    _ type: Model.Type,
    _ method: TKServer.HTTPMethod = .GET,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil
    ) -> Single<(Int?, [String: Any], Model)>
  {
    return stream(type, method, path: path, parameters: parameters, headers: headers, region: region, repeatHandler: nil)
      .map {
        if let model = $0.2 {
          return ($0.0, $0.1, model)
        } else {
          throw TKServer.ServerError.noData
        }
      }
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
  /// - returns: An observable with the status code, headers and data from hitting the endpoint, all status and data will be the same as the last call to the `repeatHandler`. Note: This will be called on a background thread.
  public func stream<Model: Decodable>(
    _ type: Model.Type,
    _ method: TKServer.HTTPMethod = .GET,
    path: String,
    parameters: [String: Any] = [:],
    headers: [String: String] = [:],
    region: TKRegion? = nil,
    repeatHandler: ((Int?, Model?) -> TKServer.RepeatHandler?)? = nil
    ) -> Observable<(Int?, [String: Any], Model?)>
  {
    let stream: Observable<(Int?, [String: Any], Data?)> = stream(
      method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region
    ) { status, maybeData in
      repeatHandler?(status, maybeData.flatMap { try? JSONDecoder().decode(Model.self, from: $0) })
    }
    return stream.map { status, header, maybeData in
      (status, headers, maybeData.flatMap { try? JSONDecoder().decode(Model.self, from: $0) })
    }
  }
  
  private func hit<Model: Decodable>(
      _ type: Model.Type,
      _ method: TKServer.HTTPMethod = .GET,
      path: String,
      parameters: [String: Any] = [:],
      headers: [String: String] = [:],
      region: TKRegion? = nil,
      repeatHandler: @escaping (Int?, [String: Any], Result<Model, Error>) -> TKServer.RepeatHandler?
    ) {

    hit(
      method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      repeatHandler: { status, headers, dataResult in
        repeatHandler(status, headers, Result {
          let data = try dataResult.get()
          return try JSONDecoder().decode(Model.self, from: data)
        })
      }
    )
  }
  
  private func hit(
      _ method: TKServer.HTTPMethod = .GET,
      path: String,
      parameters: [String: Any] = [:],
      headers: [String: String] = [:],
      region: TKRegion? = nil,
      repeatHandler: @escaping (Int?, [String: Any], Result<Data, Error>) -> TKServer.RepeatHandler?
    ) {

    self.base.hit(
      method,
      path: path,
      parameters: parameters,
      headers: headers,
      region: region,
      callbackOnMain: false
    ) { status, responseHeaders, result in
      if let hitAgain = repeatHandler(status, responseHeaders, result) {
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
            self.hit(
              method,
              path: path,
              parameters: newParameters,
              headers: headers,
              region: region,
              repeatHandler: repeatHandler
            )
          }
        }
      }
    }
  }
}

private class Stopper {
  var stop = false
}
