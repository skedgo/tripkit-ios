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
      case emails
      case phones
      case userId
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


