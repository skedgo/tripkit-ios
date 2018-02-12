//
//  Shape+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import MapKit

@objc(Shape)
public class Shape: NSManagedObject {

  fileprivate var _sortedCoordinates: [SGKNamedCoordinate]?
  
  fileprivate var sortedCoordinates: [SGKNamedCoordinate]? {
    get {
      if let encoded = encodedWaypoints, _sortedCoordinates == nil {
        let coordinates = CLLocationCoordinate2D.decodePolyline(encoded)
        _sortedCoordinates = coordinates.map(SGKNamedCoordinate.init)
      }
      return _sortedCoordinates
    }
  }
  
  @objc public weak var segment: TKSegment? = nil
  
  @objc public var start: MKAnnotation? {
    guard let first = sortedCoordinates?.first else { return nil }
    
    return first
  }

  @objc public var end: MKAnnotation? {
    guard let last = sortedCoordinates?.last else { return nil }
    
    return last
  }
  
  public override func didTurnIntoFault() {
    super.didTurnIntoFault()
    _sortedCoordinates = nil
    segment = nil
  }
  
}


extension Shape {
  @objc(fetchTravelledShapeForTemplate:atStart:)
  public static func fetchTravelledShape(for template: SegmentTemplate, atStart: Bool) -> Shape? {
    
    let predicate = NSPredicate(format: "toDelete = NO and template = %@ AND travelled = 1", template)
    let sorter = NSSortDescriptor(key: "index", ascending: atStart)
    
    let shapes = template.managedObjectContext?.fetchObjects(Shape.self, sortDescriptors: [sorter], predicate: predicate, relationshipKeyPathsForPrefetching: nil, fetchLimit: 1)
    return shapes?.first
  }
}

// MARK: - STKDisplayableRoute

extension Shape: STKDisplayableRoute {
  
  public var routePath: [Any] {
    return sortedCoordinates ?? []
  }
  
  public var routeColor: SGKColor? {
    if let travelled = travelled, !travelled.boolValue {
      // Non-travelled always gets a special colour
      return .routeDashColorNonTravelled
    }
    
    if let service = services?.anyObject() as? Service,
      let color = service.color as? SGKColor {
      return color
    }
    
    if let friendly = friendly {
      if friendly.boolValue {
        return #colorLiteral(red: 0.2862745098, green: 0.862745098, blue: 0.3882352941, alpha: 1)
      } else {
        return #colorLiteral(red: 1, green: 0.9058823529, blue: 0.2862745098, alpha: 1)
      }
    }
    
    if let color = segment?.color() {
      return color
    } else {
      return #colorLiteral(red: 0.5607843137, green: 0.5450980392, blue: 0.5411764706, alpha: 1)
    }
  }
  
  public var routeIsTravelled: Bool {
    return travelled?.boolValue ?? true
  }
  
  public var showRoute: Bool {
    return true
  }
  
  public var routeDashPattern: [NSNumber]? {
    return nil
  }
    
  
}

