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
  
  private enum Flag: Int32 {
    case isSafe     = 1
    case isNotSafe  = 2
    case dismount   = 4
    case isHop      = 8
  }

  fileprivate var _sortedCoordinates: [TKNamedCoordinate]?
  
  fileprivate var sortedCoordinates: [TKNamedCoordinate]? {
    get {
      if let encoded = encodedWaypoints, _sortedCoordinates == nil {
        let coordinates = CLLocationCoordinate2D.decodePolyline(encoded)
        _sortedCoordinates = coordinates.map(TKNamedCoordinate.init)
      }
      return _sortedCoordinates
    }
  }
  
  @objc public weak var segment: TKSegment? = nil
  
  public override func didTurnIntoFault() {
    super.didTurnIntoFault()
    _sortedCoordinates = nil
    segment = nil
  }
  
  @objc public var start: MKAnnotation? {
    return sortedCoordinates?.first
  }

  @objc public var end: MKAnnotation? {
    return sortedCoordinates?.last
  }
  
  @objc
  public var isDismount: Bool {
    get {
      return has(.dismount)
    }
    set {
      set(.dismount, to: newValue)
    }
  }
  
  @objc
  public var isHop: Bool {
    get {
      return has(.isHop)
    }
    set {
      set(.isHop, to: newValue)
    }
  }
  
  public var isSafe: Bool? {
    if has(.isSafe) {
      return true
    } else if has(.isNotSafe) {
      return false
    } else {
      return nil
    }
  }
  
  @objc
  public func setSafety(_ value: NSNumber?) {
    switch value?.boolValue {
    case true?:
      set(.isSafe, to: true)
      set(.isNotSafe, to: false)
    case false?:
      set(.isSafe, to: false)
      set(.isNotSafe, to: true)
    case nil:
      set(.isSafe, to: false)
      set(.isNotSafe, to: false)
    }
  }
  
  private func has(_ flag: Flag) -> Bool {
    return (flags & flag.rawValue) != 0
  }
  
  private func set(_ flag: Flag, to value: Bool) {
    if value {
      flags = flags | flag.rawValue
    } else {
      flags = flags & ~flag.rawValue
    }
  }
}

extension Shape {
  
  public var friendliness: TKPathFriendliness {
    if isDismount {
      return .dismount
    } else if let friendly = isSafe {
      return friendly ? .friendly : .unfriendly
    } else {
      return .unknown
    }
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

// MARK: - TKDisplayableRoute

extension Shape: TKDisplayableRoute {
  
  public var routePath: [Any] {
    return sortedCoordinates ?? []
  }
  
  public var routeColor: TKColor? {
    if let travelled = travelled, !travelled.boolValue {
      // Non-travelled always gets a special colour
      return .routeDashColorNonTravelled
    }
    
    if let service = services?.anyObject() as? Service,
      let color = service.color as? TKColor {
      return color
    }
    
    switch friendliness {
    case .friendly, .unfriendly, .dismount:
      return friendliness.color
    case .unknown:
      return segment?.color ?? friendliness.color
    }
  }
  
  public var routeIsTravelled: Bool {
    return travelled?.boolValue ?? true
  }
  
  public var showRoute: Bool {
    return true
  }
  
  public var routeDashPattern: [NSNumber]? {
    if isHop {
      return [1, 15] // dots
    } else {
      return nil
    }
  }
    
  
}

