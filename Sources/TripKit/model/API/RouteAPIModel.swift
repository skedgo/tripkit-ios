//
//  RouteAPIModel.swift
//  TripKit
//
//  Created by Adrian Schönig on 27/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension TKAPI {
  
  public struct Route: Codable, Hashable {
    public let regionCode: String
    public let id: String
    
    public let routeName: String?
    public let routeDescription: String?
    public let shortName: String?
    private let _routeColor: RGBColor?

    public let operatorID: String
    public let operatorName: String?

    public let modeInfo: TKModeInfo
    
    @available(*, deprecated, renamed: "shortName")
    public var number: String? { shortName }
    
    @available(*, deprecated, renamed: "routeName")
    public var name: String? { routeName }
    
#if !os(Linux)
    public var routeColor: TKColor? { _routeColor?.color }
    
    /// This color applies to an individual service.
    public var color: TKColor? { return routeColor ?? modeInfo.color }
#endif

    @DefaultEmptyArray public var directions: [RouteDirection]
    
    enum CodingKeys: String, CodingKey {
      case regionCode = "region"
      case id
      case routeName
      case routeDescription
      case shortName
      case modeInfo
      case _routeColor = "routeColor"
      case operatorID = "operatorId"
      case operatorName
      case directions
    }
  }
  
  public struct RouteDirection: Codable, Hashable {
    public let id: String
    
    public let name: String?
    public let encodedShape: String
    public let shapeIsDetailed: Bool
    public let stops: [DirectionStop]
  }
  
  public struct DirectionStop: Codable, Hashable {
    public let stopCode: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let isCommon: Bool
    
    enum CodingKeys: String, CodingKey {
      case stopCode
      case name
      case latitude = "lat"
      case longitude = "lng"
      case isCommon
    }
  }
  
}
