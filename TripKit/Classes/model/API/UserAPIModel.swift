//
//  UserAPIModel.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 23/4/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension API {
  
  public struct User: Codable {
    public let givenName: String?
    public let surname: String?
    public let address1: String?
    public let address2: String?
    public let postCode: String?
    public let emails: [Email]?
    public let phones: [Phone]?
    public let userId: String?
    public let appData: [String : String]? // TODO: Can we make this more generic?
    
    public init(
      firstName: String? = nil,
      lastName: String? = nil,
      address1: String? = nil,
      address2: String? = nil,
      postCode: String? = nil,
      emails: [Email]? = nil,
      phones: [Phone]? = nil,
      userId: String? = nil,
      appData: [String : String]? = nil
      ) {
      self.givenName = firstName
      self.surname = lastName
      self.address1 = address1
      self.address2 = address2
      self.postCode = postCode
      self.emails = emails
      self.phones = phones
      self.userId = userId
      self.appData = appData
    }
  }
  
  public struct Phone: Codable {
    public let phoneCode: String?
    public let phone: String
    let validated: Bool?
    public let type: String?
    public let id: String?
    
    public init(number: String, countryCode: String? = nil, validated: Bool = false, type: String? = nil, id: String? = nil) {
      self.phoneCode = countryCode
      self.phone = number
      self.validated = validated
      self.type = type
      self.id = id
    }
    
    var isValidated: Bool { return validated ?? false }
  }
  
  public struct Email: Codable {
    public let email: String
    let validated: Bool?
    let primary: Bool?
    
    public init(address: String, validated: Bool = false, primary: Bool = false) {
      self.email = address
      self.validated = validated
      self.primary = primary
    }
    
    var isValidated: Bool { return validated ?? false }
    var isPrimary: Bool { return primary ?? false }
  }
  
}


