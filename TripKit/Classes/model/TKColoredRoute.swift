//
//  TKColoredRoute.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class TKColoredRoute: NSObject {
  
  @objc public let path: [MKAnnotation]
  public let routeColor: TKColor?
  public let routeDashPattern: [NSNumber]?
  public let routeIsTravelled: Bool
  
  @objc public init(path: [MKAnnotation], color: TKColor?, dashPattern: [NSNumber]?, isTravelled: Bool) {
    self.path = path
    routeColor = color
    routeDashPattern = dashPattern
    routeIsTravelled = isTravelled
  }

  @objc(initWithWaypoints:from:to:withColor:dashPattern:isTravelled:)
  public init(path: [MKAnnotation], from: Int, to: Int, color: TKColor?, dashPattern: [NSNumber]?, isTravelled: Bool) {
    let validTo = to > from ? to : path.count
    let first = max(0, min(from, validTo))
    let last  = min(path.count, max(from, validTo))
    self.path = Array(path[first..<last])
    routeColor = color
    routeDashPattern = dashPattern
    routeIsTravelled = isTravelled
  }
  
}

extension TKColoredRoute: TKDisplayableRoute {
  
  public var routePath: [Any] {
    return path
  }
  
  public var showRoute: Bool { return true }
  
}

