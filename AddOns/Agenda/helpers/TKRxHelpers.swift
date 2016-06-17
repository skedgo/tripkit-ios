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

enum HTTPMethod: String {
  case POST = "POST"
  case GET = "GET"
  case DELETE = "DELETE"
  case PUT = "PUT"
}

extension SVKServer {
  func rx_requireRegion(coordinateRegion: MKCoordinateRegion) -> Observable<SVKRegion> {
    return Observable.create { subscriber in
      self.requireRegions { error in
        guard error == nil else {
          subscriber.onError(error!)
          return
        }
        
        let region = SVKRegionManager.sharedInstance().regionForCoordinateRegion(coordinateRegion)
        subscriber.onNext(region)
        subscriber.onCompleted()
      }
      
      return NopDisposable.instance
    }
  }
  
  func rx_hit(method: HTTPMethod, path: String, parameters: [String: AnyObject] = [:], region: SVKRegion? = nil) -> Observable<(Int, JSON?)> {
    return Observable.create { subscriber in
      self.hitSkedGoWithMethod(method.rawValue, path: path, parameters: parameters, region: region, success: { response in
        
          if let response = response {
            let json = JSON(response)
            subscriber.onNext((200, json))
          } else {
            subscriber.onNext((200, nil))
          }
          subscriber.onCompleted()
        
        }, failure: { error in
          subscriber.onError(error)
        }
      )
      
      return NopDisposable.instance
    }
  }
}
