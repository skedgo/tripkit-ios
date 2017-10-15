//
//  BPKForm.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 31/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import SwiftyJSON

extension BPKForm {
  
  // MARK: - Uber stuff -
  
  @objc public var surgePricingInEffect: Bool {
    return hasFieldWithID("disregardURL")
  }
  
  @objc public var surgePricingURL: URL? {
    guard surgePricingInEffect == true else { return nil }
    guard let urlString = stringValueForFormFieldWithID("auth") else { return nil }
    return URL(string: urlString)
  }
  
  @objc public var disregardURL: URL? {
    guard let urlString = stringValueForFormFieldWithID("disregardURL") else { return nil }
    return URL(string: urlString)
  }
  
  @objc var bookingURL: URL? {
    if !isActionBooking() { return nil }
    guard let urlString = actionURL()?.absoluteString else { return nil }
    return URL(string: urlString)
  }
  
  // MARK: - OAuth related -
  
  @objc public var isOAuthForm: Bool {
    if let type = self.rawForm["type"] as? String, type == "authForm" {
      return true
    }
    return false
  }
  
  @objc public var isClientSideOAuth: Bool {
    return isOAuthForm && oauthParameters != nil
  }
  
  @objc public var requiresOAuth: Bool {
    return isOAuthForm
  }
  
  private var oauthURL: String? {
    return stringValueForFormFieldWithID("authURL")
  }
  
  private var tokenURL: String? {
    return stringValueForFormFieldWithID("tokenURL")
  }
  
  private var oauthClientID: String? {
    return stringValueForFormFieldWithID("clientID")
  }
  
  private var oauthClientSecret: String? {
    return stringValueForFormFieldWithID("clientSecret")
  }
  
  private var oauthScope: String? {
    return stringValueForFormFieldWithID("scope")
  }
  
  private var oauthPostURL: URL? {
    guard let urlString = swiftyForm["action"]["url"].string else { return nil }
    return URL(string: urlString)
  }

  var oauthParameters: OAuthParameter? {
    guard let provider = stringValueForFormFieldWithID("provider"),
          let id = oauthClientID,
          let secret = oauthClientSecret,
          let authURL = oauthURL,
          let tokenURL = tokenURL,
          let scope = oauthScope,
          let postURL = oauthPostURL,
          let accessTokenBasicAuthRaw = stringValueForFormFieldWithID("accessTokenBasicAuth")
      else
    {
        return nil
    }
    
    let accessTokenBasicAuth = (accessTokenBasicAuthRaw == "true")
    return OAuthParameter(provider: provider, clientID: id, clientSecret: secret, oauthURL: authURL, tokenURL: tokenURL, scope: scope, postURL: postURL, accessTokenBasicAuth: accessTokenBasicAuth)
  }
  
  @objc func buildOAuthForm(_ accessToken: String, refreshToken: String?, expiration: TimeInterval) -> BPKForm? {
    guard let formFields = formFields() else { return nil }
    
    // Get the fields that are to be used to transport OAuth data
    let hiddenNilValueFields = formFields.filter { field in
      let isHidden = field["hidden"].boolValue
      let value = field["value"].string ?? ""
      let isEmpty = value.count == 0
      return isHidden && isEmpty
    }
    
    guard hiddenNilValueFields.count > 0 else { return nil }
    
    // There are dictionareis that represent OAuth data.
    var dictionaries = [[String: Any]]()
    
    for field in hiddenNilValueFields {
      var newField = [String: Any]()
      
      // Copy the id and type fields.
      newField["id"] = field["id"].stringValue
      newField["type"] = field["type"].stringValue
      
      // Assign value to the value field
      switch field["id"].string {
      case "access_token"?:
        newField["value"] = accessToken
      case "refresh_token"?:
        newField["value"] = refreshToken ?? ""
      case "expires_in"?:
        newField["value"] = String(Int(expiration))
      default:
        break
      }
      
      dictionaries.append(newField)
    }
    
    // Build to a format that's recognized by our backend
    let input = ["input": dictionaries]
    
    return BPKForm(json: input)
  }
  
  // MARK: -
  
  private func stringValueForFormFieldWithID(_ id: String) -> String? {
    guard let fields = formFields() else { return nil }
    
    let matchField = fields.filter { field in
      return field["id"].string == id
      }.first
    
    guard let mf = matchField else { return nil }
    return mf["value"].string
  }
  
  @objc public var tripUpdateURL: URL? {
    return self.refreshURLForSourceObject()
  }
  
  private var swiftyForm: JSON {
    return JSON(self.rawForm)
  }
  
  private func formFields() -> [JSON]? {
    return swiftyForm["form"][0]["fields"].array
  }
  
  private func hasFieldWithID(_ id: String) -> Bool {
    guard let fields = formFields() else { return false }
    
    let matchFields = fields
      .flatMap { (aField) -> String? in
        aField["id"].string
      }
      .filter { $0 == id }
    
    return matchFields.count > 0
  }
  
}
