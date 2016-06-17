//
//  TKAgendaUtils.swift
//  RioGo
//
//  Created by Adrian Schoenig on 6/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

extension NSDateComponents {
  func earliestDate() -> NSDate {
    let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    return calendar!.dateFromComponents(self)!
  }

  func latestDate() -> NSDate {
    return earliestDate().dateByAddingTimeInterval(86400)
  }
}

extension TKAgendaType {
  func applies(forDateComponents components: NSDateComponents) -> Bool {
    return components.earliestDate() == startDate
  }
}

extension MKCoordinateRegion {
  static func forItems(items: [TKAgendaInputItem]) -> MKCoordinateRegion {
    let mapRect = items.reduce(MKMapRectNull) { mapRect, item in
      if case let .Event(eventInput) = item where CLLocationCoordinate2DIsValid(eventInput.coordinate) {
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
