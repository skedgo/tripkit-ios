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
    public let id: String
    
    public let routeName: String?
    public let routeDescription: String?
    public let shortName: String?
    private let _routeColor: RGBColor?

    public let operatorID: String?
    public let operatorName: String?

    public let modeInfo: TKModeInfo
    
    @available(*, deprecated, renamed: "shortName")
    public var number: String? { shortName }
    
    @available(*, deprecated, renamed: "routeName")
    public var name: String? { routeName }
    
    public var routeColor: TKColor? { _routeColor?.color }
    
    /// This color applies to an individual service.
    public var color: TKColor? { return routeColor ?? modeInfo.color }

    enum CodingKeys: String, CodingKey {
      case id
      case routeName
      case routeDescription
      case shortName
      case modeInfo
      case _routeColor = "routeColor"
      case operatorID = "operatorId"
      case operatorName
    }
  }
  
}
