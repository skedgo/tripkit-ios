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
    }


    public let code: String
    public let lat: CLLocationDegrees
    public let lng: CLLocationDegrees
    public let timeZoneName: String

    public let name: String
    public let shortName: String?
    public let address: String?
    public let services: String?
    public let popularity: Int?
    public let zoneID: String?
    
    public let wheelchairAccessible: Bool?

    public let children: [Stop]?
    public let modeInfo: TKModeInfo
    
    public let alertHashCodes: [Int]?
  }
  
}
