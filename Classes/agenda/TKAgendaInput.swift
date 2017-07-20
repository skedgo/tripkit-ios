//
//  TKAgendaInput.swift
//  TripKit
//
//  Created by Adrian Schoenig on 13/6/17.
//

import Foundation

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
    public let location: Location
    public let startTime: Date
    public let endTime: Date
    public let priority: Priority

    public let color: SGKColor?
    public let description: String?
    public let url: URL?
    public let excluded: Bool
    public let direct: Bool
    
    public init(id: String, title: String, location: Location, startTime: Date, endTime: Date, priority: Priority, color: SGKColor? = nil, description: String? = nil, url: URL? = nil, excluded: Bool = false, direct: Bool = false) {
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
  
  public let installationId: String?
  public let confirmToOverwriteId: String?
  
  public let config: [String: Any]
  
  public let items: [Item]
  
  public let patterns: [TKSegmentPattern]
  
  public let modes: [String]
  
  public let vehicles: [String: Any]

  public init(items: [Item], modes: [String] = [], config: [String:Any] = [:], patterns: [TKSegmentPattern] = [], vehicles: [String: Any] = [:], installationId: String? = nil, overwritingId: String? = nil) {
    self.items = items
    self.modes = modes
    self.config = config
    self.patterns = patterns
    self.vehicles = vehicles
    self.installationId = installationId
    self.confirmToOverwriteId = overwritingId
  }
  
}
