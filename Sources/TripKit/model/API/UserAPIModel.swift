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
    public let givenName: String?
    public let familyName: String?
    public let address1: String?
    public let address2: String?
    public let postCode: String?
    public let phone: String?
    public let phones: [Phone]?
    public let highResProfilePictureURL: URL?
    public let lowResProfilePictureURL: URL?
    public let userType: String?
    public var appData: [String : Any]?
    private let rawUserId: String?
    private let rawEmail: String?
    private let rawEmails: [Email]?
    
    @available(*, unavailable, renamed: "givenName")
    public var firstName: String? { givenName }

    @available(*, unavailable, renamed: "familyName")
    public var lastName: String? { familyName }

    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
      case name
      case givenName
      case familyName = "surname"
      case address1
      case address2
      case postCode
      case phone
      case phones
      case highResProfilePictureURL = "largeImageURL"
      case lowResProfilePictureURL = "smallImageURL"
      case userType
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


