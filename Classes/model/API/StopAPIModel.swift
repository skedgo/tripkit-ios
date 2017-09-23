//
//  StopAPIModel.swift
//  TripKit
//
//  Created by Adrian Schoenig on 22.09.17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension API {

  public struct Stop: Codable {
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
    }


    let code: String
    let lat: CLLocationDegrees
    let lng: CLLocationDegrees
    let timeZoneName: String

    let name: String
    let shortName: String?
    let address: String?
    let services: String?
    let popularity: Int?
    
    let wheelchairAccessible: Bool?

    let children: [Stop]?
    let modeInfo: ModeInfo
  }
  
}
