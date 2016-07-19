//
//  TKRxHelpers.swift
//  RioGo
//
//  Created by Adrian Schoenig on 16/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift
import SwiftyJSON

import SGCoreKit

public enum HTTPMethod: String {
  case POST = "POST"
  case GET = "GET"
  case DELETE = "DELETE"
  case PUT = "PUT"
}

extension SVKServer {
  public func rx_requireRegion(coordinate: CLLocationCoordinate2D) -> Observable<SVKRegion> {
    return rx_requireRegion()
      .map {
        SVKRegionManager.sharedInstance().regionForCoordinate(coordinate, andOther: coordinate)
    }
  }
  
  public func rx_requireRegion(coordinateRegion: MKCoordinateRegion) -> Observable<SVKRegion> {
    
    return rx_requireRegion()
      .map {
        SVKRegionManager.sharedInstance().regionForCoordinateRegion(coordinateRegion)
    }
  }
  
  private func rx_requireRegion() -> Observable<Void> {
    return Observable.create { subscriber in
      self.requireRegions { error in
        guard error == nil else {
          subscriber.onError(error!)
          return
        }
        
        subscriber.onNext()
        subscriber.onCompleted()
      }
      
      return NopDisposable.instance
    }
    
  }

  
  public func rx_hit(method: HTTPMethod, path: String, parameters: [String: AnyObject] = [:], region: SVKRegion? = nil, repeatHandler: ((Int, JSON?) -> (Bool))? = nil) -> Observable<(Int, JSON?)> {
    return Observable.create { subscriber in
      
      self.hitSkedGo(
        method,
        path: path,
        parameters: parameters,
        region: region,
        repeatHandler: { code, json in
          
          let hitAgain: Bool
          if let repeatHandler = repeatHandler {
            hitAgain = repeatHandler(code, json)
          } else {
            hitAgain = false
          }

          subscriber.onNext(code, json)
          if !hitAgain {
            subscriber.onCompleted()
          }
          return hitAgain
          
        }, errorHandler: { error in
          subscriber.onError(error)
        }
      )
      
      return NopDisposable.instance
    }
  }
  
  private func hitSkedGo(method: HTTPMethod, path: String, parameters: [String: AnyObject] = [:], region: SVKRegion? = nil, repeatHandler: (Int, JSON?) -> (Bool), errorHandler: (ErrorType) -> ()) {
    
    hitSkedGoWithMethod(
      method.rawValue,
      path: path,
      parameters: parameters,
      region: region,
      callbackOnMain: false,
      success: { code, response in
        
        let json = (response != nil) ? JSON(response!) : nil
        let hitAgain = repeatHandler(code, json)
        if hitAgain {
          
          let seconds = 2.5
          let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
          let queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)

          dispatch_after(dispatchTime, queue) {
            self.hitSkedGo(
              method,
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
