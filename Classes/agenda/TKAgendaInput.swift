//
//  TKAgendaInput.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//

import Foundation

import Marshal

public struct TKAgendaInput {

  public struct Location {
    public let what3word: String?
    public let title: String?
    public let address: String?
    public let coordinate: CLLocationCoordinate2D?
    
    public init(title: String? = nil, what3word: String) {
      self.what3word = what3word
      self.title = title
      self.address = nil
      self.coordinate = nil
    }
    
    public init(title: String? = nil, coordinate: CLLocationCoordinate2D, address: String? = nil) {
      self.what3word = nil
      self.title = title
      self.address = address
      self.coordinate = coordinate
    }
    
  }
  
  public struct HomeInput {
    public let title: String?
    public let location: Location
    
    public init(title: String? = nil, location: Location) {
      self.title = title
      self.location = location
    }
  }
  
  public struct EventInput {
    public enum Priority: Int {
      case routine = 2
      case calendarEvent = 5
    }
    
    public let id: String
    public let title: String
    public let location: Location?
    public let startTime: Date
    public let endTime: Date
    public let priority: Priority

    public let color: SGKColor?
    public let description: String?
    public let url: URL?
    public let excluded: Bool
    public let direct: Bool
    
    public init(id: String, title: String, location: Location?, startTime: Date, endTime: Date, priority: Priority, color: SGKColor? = nil, description: String? = nil, url: URL? = nil, excluded: Bool = false, direct: Bool = false) {
      self.id = id
      self.title = title
      self.location = location
      self.startTime = startTime
      self.endTime = endTime
      self.priority = priority
      self.color = color
      self.description = description
      self.url = url
      self.excluded = excluded
      self.direct = direct
    }
  }
  
  public struct TripInput {
    public let url: URL
    
    // TODO: Fill in
  }
  
  public enum Item {
    case home(HomeInput)
    case event(EventInput)
    case trip(TripInput)
    
    public var type: String {
      switch self {
      case .home: return "home"
      case .event: return "event"
      case .trip: return "trip"
      }
    }

  }
  
  public let config: [String: Any]
  
  public let items: [Item]
  
  public let patterns: [TKSegmentPattern]
  
  public let modes: [String]
  
  public let vehicles: [String: Any]

  public init(items: [Item], modes: [String] = [], config: [String:Any] = [:], patterns: [TKSegmentPattern] = [], vehicles: [String: Any] = [:]) {
    self.items = items
    self.modes = modes
    self.config = config
    self.patterns = patterns
    self.vehicles = vehicles
  }
  
}

// MARK: - Marshaling

extension TKAgendaInput: Marshaling {

  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    return [
      "items": items.map { $0.marshaled() },
      "config": config,
      "patterns": patterns,
      "modes": modes,
      "vehicles": vehicles,
    ]
  }
  
}

extension TKAgendaInput.Item: Marshaling {
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled: MarshalType
    
    switch self {
    case .home(let input):  marshaled = input.marshaled()
    case .event(let input): marshaled = input.marshaled()
    case .trip(let input):  marshaled = input.marshaled()
    }
    
    marshaled["type"] = type
    return marshaled
  }
  
}

extension TKAgendaInput.Location: Marshaling {
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled = MarshalType()
    marshaled["what3word"] = what3word
    marshaled["title"] = title
    marshaled["address"] = address
    
    if let coordinate = coordinate {
      marshaled["lat"] = coordinate.latitude
      marshaled["lng"] = coordinate.longitude
    }
    
    return marshaled
  }
  
}

extension TKAgendaInput.HomeInput: Marshaling {
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled: MarshalType =  [
      "location": location.marshaled(),
    ]
    
    marshaled["title"] = title
    return marshaled
  }
  
}

extension TKAgendaInput.EventInput: Marshaling {
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    var marshaled: MarshalType =  [
      "id": id,
      "title": title,
      "startTime": startTime.iso8601,
      "endTime": endTime.iso8601,
      "priority": priority.rawValue,
    ]
    
    marshaled["location"] = location?.marshaled()
    marshaled["color"] = color?.marshaled()
    marshaled["description"] = description
    marshaled["url"] = url?.absoluteString
    
    if excluded { marshaled["excluded"] = true }
    if direct   { marshaled["direct"]   = true }
    
    return marshaled
  }
  
}

extension TKAgendaInput.TripInput: Marshaling {
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    let marshaled: MarshalType =  [
      "url": url.absoluteString,
    ]
    
    return marshaled
  }
  
}

extension SGKColor {
  
  public var RGBA: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    var r: CGFloat = 0.0
    var g: CGFloat = 0.0
    var b: CGFloat = 0.0
    var a: CGFloat = 0.0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return (red: r, green: g, blue: b, alpha: a)
  }
  
}

extension SGKColor: Marshaling {
  
  public typealias MarshalType = [String: Any]
  
  public func marshaled() -> MarshalType {
    let components = RGBA
    return [
      "red": components.red * 256,
      "green": components.green * 256,
      "blue": components.green * 256,
    ]
  }
  
}

// MARK: Unmarshaling

extension TKAgendaInput: Unmarshaling {
  
  public init(object: MarshaledObject) throws {

    items = try object.value(for: "items")
    modes = (try? object.value(for: "modes")) ?? []
    config = (try? object.value(for: "config")) ?? [:]
    patterns = (try? object.value(for: "patterns")) ?? []
    vehicles = (try? object.value(for: "vehicles")) ?? [:]
    
  }
  
}

extension TKAgendaInput.Item: Unmarshaling {
  
  public init(object: MarshaledObject) throws {
    let type: String = try object.value(for: "type")
    
    switch type {
    case "home":
      self = .home(TKAgendaInput.HomeInput(
        title: try? object.value(for: "title"),
        location: try object.value(for: "location")
      ))
      
    case "event":
      self = .event(TKAgendaInput.EventInput(
        id: try object.value(for: "id"),
        title: try object.value(for: "title"),
        location: try? object.value(for: "location"),
        startTime: try object.value(for: "startTime"),
        endTime: try object.value(for: "endTime"),
        priority: try object.value(for: "priority"),
        color: try? object.value(for: "color"),
        description: try? object.value(for: "description"),
        url: try? object.value(for: "url"),
        excluded: (try? object.value(for: "excluded")) ?? false,
        direct: (try? object.value(for: "direct")) ?? false
      ))
      
      
    case "trip":
      self = .trip(TKAgendaInput.TripInput(
        url: try object.value(for: "url")
        
        // TODO: Fill in rest
      ))
      
    default:
      throw MarshalError.keyNotFound(key: "type")
    }
    
  }
  
}


extension TKAgendaInput.Location: Unmarshaling {
  
  public init(object: MarshaledObject) throws {
    
    what3word = try? object.value(for: "what3word")
    title = try? object.value(for: "title")
    address = try? object.value(for: "address")
    
    if let lat: CLLocationDegrees = try? object.value(for: "lat"),
      let lng: CLLocationDegrees = try? object.value(for: "lng") {
      let candidate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
      if candidate.isValid {
        coordinate = candidate
      } else {
        coordinate = nil
      }
    } else {
      coordinate = nil
    }
    
  }
  
}

// MARK: - Useful helpers

extension SGKNamedCoordinate {
  public convenience init?(_ inputLocation: TKAgendaInput.Location?) {
    guard let inputLocation = inputLocation, let coordinate = inputLocation.coordinate else { return nil }
    
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, name: inputLocation.title, address: inputLocation.address)
  }
}
