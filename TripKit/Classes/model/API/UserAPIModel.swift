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
    public let name: String?
    public let firstName: String?
    public let lastName: String?
    public let address1: String?
    public let address2: String?
    public let postCode: String?
    public let email: String?
    public let emails: [Email]?
    public let phones: [Phone]?
    public let userId: String?
    public var appData: [String : Any] = [:]
    
    public init(
      name: String? = nil,
      firstName: String? = nil,
      lastName: String? = nil,
      address1: String? = nil,
      address2: String? = nil,
      postCode: String? = nil,
      email: String? = nil,
      emails: [Email]? = nil,
      phones: [Phone]? = nil,
      userId: String? = nil,
      appData: [String : Any] = [:]
      ) {
      self.name = name
      self.firstName = firstName
      self.lastName = lastName
      self.address1 = address1
      self.address2 = address2
      self.postCode = postCode
      self.email = email
      self.emails = emails
      self.phones = phones
      self.userId = userId
      self.appData = appData
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
      case name
      case firstName = "givenName"
      case lastName = "surname"
      case address1
      case address2
      case postCode
      case email
      case emails
      case phones
      case userId = "userID"
    }
    
    public init(from decoder: Decoder) throws {
      let values = try decoder.container(keyedBy: CodingKeys.self)
      userId = try? values.decode(String.self, forKey: .userId)
      name = try? values.decode(String.self, forKey: .name)
      firstName = try? values.decode(String.self, forKey: .firstName)
      lastName = try? values.decode(String.self, forKey: .lastName)
      address1 = try? values.decode(String.self, forKey: .address1)
      address2 = try? values.decode(String.self, forKey: .address2)
      postCode = try? values.decode(String.self, forKey: .postCode)
      email = try? values.decode(String.self, forKey: .email)
      phones = try? values.decode([Phone].self, forKey: .phones)
      
      if let emails = try? values.decode([Email].self, forKey: .emails) {
        // if the api returns `emails` field, use it.
        self.emails = emails
      } else if let address = try? values.decode(String.self, forKey: .email) {
        // our api only returns `email` field if, and only if, the email
        // is the primary email and is validated. So if the api does not
        // explicitly return `emails`, we can safely create one based on
        // the `email` field.
        //
        // this ticket: https://redmine.buzzhives.com/issues/11622, aims
        // to make our api more consistent.
        let primaryEmail = Email(address: address, validated: true, primary: true)
        self.emails = [primaryEmail]
      } else {
        self.emails = nil
      }
    }
  }
  
  public struct Phone: Codable {
    public let countryCode: String?
    public let number: String
    let validated: Bool?
    public let type: String?
    public let id: String?
    
    public init(number: String, countryCode: String? = nil, validated: Bool = false, type: String? = nil, id: String? = nil) {
      self.countryCode = countryCode
      self.number = number
      self.validated = validated
      self.type = type
      self.id = id
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
      case countryCode = "phoneCode"
      case number = "phone"
      case validated
      case type
      case id
    }
  }
  
  public struct Email: Codable {
    public let address: String
    public let verified: Bool
    public let primary: Bool
    
    public init(address: String, validated: Bool = false, primary: Bool = false) {
      self.address = address
      self.verified = validated
      self.primary = primary
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
      case address = "email"
      case verified = "validated"
      case primary
    }
  }
  
}


