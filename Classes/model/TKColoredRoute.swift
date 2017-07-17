//
//  TKColoredRoute.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class TKColoredRoute: NSObject {
  
  public let path: [MKAnnotation]
  public let routeColor: SGKColor?
  public let routeDashPattern: [NSNumber]?
  public let routeIsTravelled: Bool
  
  public init(path: [MKAnnotation], color: SGKColor?, dashPattern: [NSNumber]?, isTravelled: Bool) {
    self.path = path
    routeColor = color
    routeDashPattern = dashPattern
    routeIsTravelled = isTravelled
  }

  @objc(initWithWaypoints:from:to:withColor:dashPattern:isTravelled:)
  public init(path: [MKAnnotation], from: Int, to: Int, color: SGKColor?, dashPattern: [NSNumber]?, isTravelled: Bool) {
    let first = from > to ? 0 : from
    let last  = to < from ? path.count - 1 : to
    self.path = Array(path[first...last])
    routeColor = color
    routeDashPattern = dashPattern
    routeIsTravelled = isTravelled
  }
  
}

extension TKColoredRoute: STKDisplayableRoute {
  
  public var routePath: [Any] {
    return path
  }
  
  public var showRoute: Bool { return true }
  
}

