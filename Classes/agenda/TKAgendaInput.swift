//
//  TKAgendaInput.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//

import Foundation

public struct TKAgendaInput: Codable {
  
  public struct Location: Codable {
    public let what3word: String?
    public let name: String?
    public let address: String?
    private let lat: CLLocationDegrees?
    private let lng: CLLocationDegrees?
    
    public var coordinate: CLLocationCoordinate2D? {
      guard let lat = lat, let lng = lng else { return nil }
      return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    public init(name: String? = nil, what3word: String) {
      self.what3word = what3word
      self.name = name
      self.address = nil
      self.lat = nil
      self.lng = nil
    }
    
    public init(name: String? = nil, coordinate: CLLocationCoordinate2D?, address: String? = nil) {
      self.what3word = nil
      self.name = name
      self.address = address
      self.lat = coordinate?.latitude
      self.lng = coordinate?.longitude
    }
    
  }
  
  public struct HomeInput: Codable {
    public let title: String?
    public let location: Location
    
    public init(title: String? = nil, location: Location) {
      self.title = title
      self.location = location
    }
  }
  
  public struct EventInput: Codable {
    public enum Priority: Int, Codable {
      case routine = 2
      case calendarEvent = 5
    }
    
    public let id: String
    public let title: String
    public let location: Location?
    public let startTime: Date
    public let endTime: Date
    public let priority: Priority

    private let rgbColor: API.RGBColor?
    public let description: String?
    public let url: URL?
    public let excluded: Bool?
    public let direct: Bool?
    
    public init(id: String, title: String, location: Location?, startTime: Date, endTime: Date, priority: Priority, color: SGKColor? = nil, description: String? = nil, url: URL? = nil, excluded: Bool = false, direct: Bool = false) {
      self.id = id
      self.title = title
      self.location = location
      self.startTime = startTime
      self.endTime = endTime
      self.priority = priority
      self.rgbColor = API.RGBColor(for: color)
      self.description = description
      self.url = url
      self.excluded = excluded
      self.direct = direct
    }
    
    public var color: SGKColor? { return rgbColor?.color }
    
    // MARK: Codable
    
    private enum CodingKeys: String, CodingKey {
      case id
      case title
      case location
      case startTime
      case endTime
      case priority
      case rgbColor = "color"
      case description
      case url
      case excluded
      case direct
    }
  }
  
  public struct TripInput: Codable {
    public let url: URL
    
    // TODO: Fill in
  }
  
  public enum Item: Codable {
    public enum CodingError: Error {
      case unexpectedType(String)
    }
    
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
    
    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
      case type
    }
    
    public init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      switch type {
      case "event": self = .event(try EventInput(from: decoder))
      case "home":  self = .home(try HomeInput(from: decoder))
      case "trip":  self = .trip(try TripInput(from: decoder))
      default: throw CodingError.unexpectedType(type)
      }
    }
    
    public func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(type, forKey: .type)
      switch self {
      case .event(let input): try input.encode(to: encoder)
      case .home(let input):  try input.encode(to: encoder)
      case .trip(let input):  try input.encode(to: encoder)
      }
    }
  }
  
  public let config: [String: Any]
  
  public let items: [Item]
  
  public let patterns: [TKSegmentPattern]
  
  public let modes: [String]
  
  public let vehicles: [[String: Any]]

  public init(items: [Item], modes: [String] = [], config: [String:Any] = [:], patterns: [TKSegmentPattern] = [], vehicles: [[String: Any]] = []) {
    self.items = items
    self.modes = modes
    self.config = config
    self.patterns = patterns
    self.vehicles = vehicles
  }
  
  // MARK: Codable
  
  private enum CodingKeys: String, CodingKey {
    case config
    case items
    case patterns
    case modes
    case vehicles
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    config =   (try? container.decode([String: Any].self, forKey: .config)) ?? [:]
    items =     try  container.decode([Item].self, forKey: .items)
    patterns = (try? container.decode([TKSegmentPattern].self, forKey: .patterns)) ?? []
    modes =    (try? container.decode([String].self, forKey: .modes)) ?? []
    vehicles = (try? container.decode([[String: Any]].self, forKey: .vehicles)) ?? []
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(config, forKey: .config)
    try container.encode(items, forKey: .items)
    try container.encode(patterns, forKey: .patterns)
    try container.encode(modes, forKey: .modes)
    try container.encode(vehicles, forKey: .vehicles)
  }
  
}

// MARK: - Useful helpers

extension SGKNamedCoordinate {
  public convenience init?(_ inputLocation: TKAgendaInput.Location?) {
    guard let inputLocation = inputLocation, let coordinate = inputLocation.coordinate else { return nil }
    
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude, name: inputLocation.name, address: inputLocation.address)
  }
}
