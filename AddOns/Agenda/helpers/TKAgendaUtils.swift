//
//  TKAgendaUtils.swift
//  RioGo
//
//  Created by Adrian Schoenig on 6/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import MapKit

extension DateComponents {
  public func earliestDate() -> Date {
    let calendar = NSCalendar(identifier: NSCalendar.Identifier.gregorian)
    return calendar!.date(from: self)!
  }

  public func latestDate() -> Date {
    return earliestDate().addingTimeInterval(86400)
  }
}

extension TKAgendaType {
  public func applies(forDateComponents components: DateComponents) -> Bool {
    return components.earliestDate() == startDate
  }
}

extension MKCoordinateRegion {
  static func forItems(_ items: [TKAgendaInputItem]) -> MKCoordinateRegion {
    let mapRect = items.reduce(MKMapRectNull) { mapRect, item in
      if case let .event(eventInput) = item, CLLocationCoordinate2DIsValid(eventInput.coordinate) {
        let point = MKMapPointForCoordinate(eventInput.coordinate)
        let miniRect = MKMapRectMake(point.x, point.y, 0, 0)
        return MKMapRectUnion(mapRect, miniRect)
      } else {
        return mapRect
      }
    }
    return MKCoordinateRegionForMapRect(mapRect)
  }
}
