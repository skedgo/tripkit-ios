//
//  TKColoredRoute.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

public class TKColoredRoute: NSObject {
  
  @objc public private(set) var path: [MKAnnotation]
  public let routeColor: TKColor?
  public let routeDashPattern: [NSNumber]?
  public let routeIsTravelled: Bool
  
  public let selectionIdentifier: String?
  
  @objc public init(path: [MKAnnotation], color: TKColor? = nil, dashPattern: [NSNumber]? = nil, isTravelled: Bool = true, identifier: String? = nil) {
    self.path = path
    routeColor = color
    routeDashPattern = dashPattern
    routeIsTravelled = isTravelled
    self.selectionIdentifier = identifier
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
    self.selectionIdentifier = nil
  }
  
  public func append(_ annotations: [MKAnnotation]) {
    path.append(contentsOf: annotations)
  }
  
}

extension TKColoredRoute: TKDisplayableRoute {
  
  public var routePath: [Any] {
    return path
  }
  
}

