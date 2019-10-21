//
//  TKUIRoutingQueryAnnotation.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

class TKUIRoutingQueryAnnotation: NSObject, MKAnnotation {
  let title: String?
  let subtitle: String?
  let coordinate: CLLocationCoordinate2D
  let isStart: Bool
  
  init(at location: TKNamedCoordinate, isStart: Bool) {
    title = isStart ? Loc.StartLocation : Loc.EndLocation
    subtitle = location.title
    coordinate = location.coordinate
    self.isStart = isStart
  }
}
