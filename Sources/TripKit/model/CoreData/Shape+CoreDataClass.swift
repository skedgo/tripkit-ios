//
//  Shape+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schoenig on 4/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

#if canImport(CoreData)

import Foundation
import CoreData
import CoreLocation
import MapKit

@objc(Shape)
public class Shape: NSManagedObject {
  
  /// A turn-by-turn instruction, from one shape to the next
  public enum Instruction: Int16 {
    case headTowards        = 1
    case continueStraight   = 2
    case turnSlightyLeft    = 3
    case turnSlightlyRight  = 4
    case turnLeft           = 5
    case turnRight          = 6
    case turnSharplyLeft    = 7
    case turnSharplyRight   = 8
  }
  
  private enum Flag: Int32 {
    case isSafe     = 1
    case isNotSafe  = 2
    case dismount   = 4
    case isHop      = 8
  }

  fileprivate var _sortedCoordinates: [TKNamedCoordinate]?
  
  public var sortedCoordinates: [TKNamedCoordinate]? {
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
  
  /// The turn-by-turn instruction from the previous shape to this shape
  public var instruction: Instruction? {
    get {
      return Instruction(rawValue: rawInstruction)
    }
    set {
      rawInstruction = newValue?.rawValue ?? 0
    }
  }
  
  /// Indicates if you need to dismount your vehicle (e.g., your bicycle) to traverse this shape
  @objc
  public var isDismount: Bool {
    get {
      return has(.dismount)
    }
    set {
      set(.dismount, to: newValue)
    }
  }
  
  /// A hop is a shape element where the actual path is unknown and the indicated waypoints
  /// can not be relied on.
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
  
  func setSafety(_ bool: Bool?) {
    switch bool {
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
  static func fetchTravelledShape(for template: SegmentTemplate, atStart: Bool) -> Shape? {
    
    let predicate = NSPredicate(format: "template = %@ AND travelled = 1", template)
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
    if !travelled {
      // Non-travelled always gets a special colour
      return .routeDashColorNonTravelled
    }
    
    if let color = services?.first?.color {
      return color
    }
    
#if os(iOS) || os(tvOS) || os(visionOS)
    if let bestTag = roadTags?.first {
      return bestTag.safety.color
    }
    
    // This reflects "Do we show the little chart of road tag", i.e., are there
    // any tags on this segment to show other than just "Other". If so, we
    // default no tags to "Other" for the colour here.
    if segment?.distanceByRoadTags != nil {
      return RoadTag.other.safety.color
    }
#endif
    
    switch friendliness {
    case .friendly, .unfriendly, .dismount:
      return friendliness.color
    case .unknown:
      return segment?.color ?? friendliness.color
    }
  }
  
  public var routeIsTravelled: Bool {
    return travelled
  }
  
  public var routeDashPattern: [NSNumber]? {
    if isHop {
      return [1, 15] // dots
    } else {
      return nil
    }
  }
  
  public var selectionIdentifier: String? {
    if let segment = segment?.originalSegmentIncludingContinuation() {
      
      // Should match the definition in TripKitUI => TKUIAnnotations+TripKit
      switch segment.order {
      case .start: return "start"
      case .regular: return String(segment.templateHashCode)
      case .end: return "end"
      }

    } else if let service = services?.first {
      return service.code
    } else {
      return nil
    }
  }
  
}

#endif
