//
//  UserAPIModel.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 23/4/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension TKAPI {
  
  public struct User: Codable {
    public let name: String?
    public let firstName: String?
    public let lastName: String?
    public let address1: String?
    public let address2: String?
    public let postCode: String?
    public let phones: [Phone]?
    public var appData: [String : Any]?
    private let rawUserId: String?
    private let rawEmail: String?
    private let rawEmails: [Email]?
    
    public init(name: String? = nil,
                firstName: String? = nil,
                lastName: String? = nil,
                address1: String? = nil,
                address2: String? = nil,
                postCode: String? = nil,
                email: String? = nil,
                phone: String? = nil,
                appData: [String: Any]? = nil) {
      self.name = name
      self.firstName = firstName
      self.lastName = lastName
      self.address1 = address1
      self.address2 = address2
      self.postCode = postCode
      self.rawEmail = email
      self.rawEmails = rawEmail.flatMap { [Email(address: $0)] }
      self.phones = phone.flatMap { [Phone(number: $0)] }
      self.rawUserId = nil // This is not set directly
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
      case name
      case firstName = "givenName"
      case lastName = "surname"
      case address1
      case address2
      case postCode
      case phones
      case rawEmail = "email"
      case rawEmails = "emails"
      case rawUserId = "userID"
    }
    
    public var userId: String? { return rawUserId }
    
    public var emails: [Email]? {
      if let emails = rawEmails { return emails }
      else if let email = rawEmail { return [Email(address: email, validated: true, primary: true)] }
      else { return nil }
    }
  }
  
  public struct Phone: Codable, Hashable {
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
  
  public struct Email: Codable, Hashable {
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


