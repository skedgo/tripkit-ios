//
//  AMKCommunicator.swift
//  TripGo
//
//  Created by Adrian Schoenig on 2/06/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

extension AMKCommunicator {
  
  public static func signIn(withCloudKitID cloudKitID: String) -> Observable<String> {
    return Observable.create { subscriber in
      let urlFriendly = cloudKitID.replacingOccurrences(of: "_", with: "")
      SVKServer.sharedInstance().hitSkedGo(withMethod: "POST",
        path: "account/apple/\(urlFriendly)",
        parameters: [:],
        region: nil,
        success: { _, responseObject in
          findToken(inResponse: responseObject) { userToken, error in
            if let userToken = userToken {
              subscriber.onNext(userToken)
              subscriber.onCompleted()
            } else {
              subscriber.onError(error!)
            }
          }
          
        },
        failure: { error in
          subscriber.onError(error)
        }
      )
      
      return Disposables.create()
    }
  }
  
}
