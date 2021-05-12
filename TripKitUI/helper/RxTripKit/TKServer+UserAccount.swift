//
//  TKServer+UserAccount.swift
//  TripKit
//
//  Created by Adrian Schönig on 02.03.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension Reactive where Base == TKServer {
  
  /// Sign the user in using a token from CloudKit, returning
  /// the user token.
  ///
  /// - Note: The token is only retrieved, but not stored. Most
  ///     likely you'll next want to call
  ///     `TKServer.updateUserToken(_:)`.
  ///
  /// - Note: There's no need to sign-up first. If this is the
  ///     sign-in attempt an account with no information but the
  ///     cloud kit ID will be created.
  ///
  /// - Parameter cloudKitID: The record name of the CloudKit's
  ///     user record ID.
  /// - Returns: The user token. Can fail.
  public func signIn(withCloudKitID cloudKitID: String) -> Single<String> {
    return signIn(token: cloudKitID, endpoint: "apple")
  }
  
  /// Sign the user in using a UUID, which you might sync using whichever means
  /// you prefer.
  ///
  /// - Note: The token is only retrieved, but not stored. Most
  ///     likely you'll next want to call
  ///     `TKServer.updateUserToken(_:)`.
  ///
  /// - Note: There's no need to sign-up first. If this is the
  ///     sign-in attempt an account with no information but the
  ///     UUID will be created.
  ///
  /// - Parameter uuid: A UUID of your choosing
  /// - Returns: The user token. Can fail.
  public func signIn(withUUID uuid: String) -> Single<String> {
    return signIn(token: uuid, endpoint: "uuid")
  }
  
  private func signIn(token: String, endpoint: String) -> Single<String> {
    let urlFriendly = token.replacingOccurrences(of: "_", with: "")
    return hit(.POST, path: "account/\(endpoint)/\(urlFriendly)")
      .map { _, _, data in
        guard let data = data, let response = try? JSONDecoder().decode(SignInResponse.self, from: data) else {
          throw TKError.error(withCode: 1301, userInfo: [ NSLocalizedDescriptionKey: "Cannot find a valid token" ])
        }
        return response.userToken
    }
  }
  
  /// Fetches all server-side data for a user, returning it as raw data, which
  /// can be turned in a JSON string or file.
  ///
  /// - Note: Only returns data if a `userToken` was previously set.
  ///
  /// - Returns: Data, if any was available
  public func downloadUserData() -> Single<Data> {
    return hit(.GET, path: "data/user/gdpr")
      .map { status, _, data in
        if let data = data {
          return data
        } else {
          throw TKError.error(withCode: 16523, userInfo: [ NSLocalizedDescriptionKey: "No server-side data" ])
        }
    }
  }
  
  /// Deletes all server-side data for a user, and also signs them out by
  /// resetting the user token
  public func deleteUserDataAndSignOut() -> Single<Void> {
    return hit(.DELETE, path: "data/user/gdpr")
      .map { status, _, _ in
        if status != 200 {
          throw TKError.error(withCode: 16524, userInfo: [ NSLocalizedDescriptionKey: "Couldn't delete account. Status: \(status)" ])
        } else {
          TKServer.updateUserToken(nil)
        }
    }
  }
  
}

fileprivate struct SignInResponse: Codable {
  let userToken: String
}
