//
//  SVKServer+UserAccount.swift
//  TripKit
//
//  Created by Adrian Schönig on 02.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

extension Reactive where Base == SVKServer {
  
  /// Sign the user in using a token from CloudKit, returning
  /// the user token.
  ///
  /// - Note: The token is only retrieved, but not stored. Most
  ///     likely you'll next want to call
  ///     `SVKServer.updateUserToken(_:)`.
  ///
  /// - Note: There's no need to sign-up first. If this is the
  ///     sign-in attempt an account with no information but the
  ///     cloud kit ID will be created.
  ///
  /// - Parameter cloudKitID: The record name of the CloudKit's
  ///     user record ID.
  /// - Returns: The user token
  public func signIn(withCloudKitID cloudKitID: String) -> Observable<String> {
    
    let urlFriendly = cloudKitID.replacingOccurrences(of: "_", with: "")
    return hit(.POST, path: "account/apple/\(urlFriendly)")
      .map { _, _, data in
        guard let data = data, let response = try? JSONDecoder().decode(SignInResponse.self, from: data) else {
          throw SVKError.error(withCode: 1301, userInfo: [ NSLocalizedDescriptionKey: "Cannot find a valid token" ])
        }
        return response.userToken
      }
  }
  
}

struct SignInResponse: Codable {
  let userToken: String
}
