//
//  StopAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension TKAPI {

  public struct Stop: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
      case code
      case lat
      case lng
      case timeZoneName = "timezone"
      case name
      case shortName
      case address
      case services
      case popularity
      case wheelchairAccessible
      case children
      case modeInfo
      case alertHashCodes
      case zoneID
      case availableRoutes
      case operators
      case routes
    }

    public let code: String
    public let lat: Degrees
    public let lng: Degrees
    public let timeZoneName: String

    public let name: String
    public let shortName: String?
    public let address: String?
    public let services: String?
    public let popularity: Int?
    public let zoneID: String?
    public let availableRoutes: Int?

    public let wheelchairAccessible: Bool?

    @DefaultEmptyArray public var children: [Stop]
    
    public let modeInfo: TKModeInfo
    
    public let operators: [Operator]?
    
    public let routes: [Route]?
    
    @DefaultEmptyArray public var alertHashCodes: [Int]
    
  }
  
  public struct Operator: Codable, Hashable {
    public let id: String?
    public let name: String?
  }
  
}
