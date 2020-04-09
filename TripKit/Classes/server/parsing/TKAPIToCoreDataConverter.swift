//
//  TKAPIToCoreDataConverter.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

/// :nodoc:
@objc
public class TKAPIToCoreDataConverter: NSObject {
  override private init() {
    super.init()
  }
}

// MARK: - Stops

/// :nodoc:
extension StopLocation {

  func update(from model: TKAPI.Stop) -> Bool {
    guard let context = managedObjectContext else {
      assertionFailure("Stop has no context")
      return false
    }
    
    stopCode  = model.code
    shortName = model.shortName
    
    if let popularity = model.popularity {
      sortScore = NSNumber(value: popularity)
    }

    self.wheelchairAccessibility = TKWheelchairAccessibility(bool: model.wheelchairAccessible)

    location = TKNamedCoordinate(latitude: model.lat, longitude: model.lng, name: model.name, address: model.services)
    stopModeInfo = model.modeInfo
    
    var addedStop = false
    if let newChildren = model.children {
      let lookup = Dictionary(grouping: children ?? []) {
        $0.stopCode
      }
      for newChild in newChildren {
        if let oldChild = lookup[newChild.code]?.first {
          addedStop = oldChild.update(from: newChild) || addedStop
        } else {
          let child = TKAPIToCoreDataConverter.insertNewStopLocation(from: newChild, into: context)
          addedStop = true
          child.parent = self
        }
      }
    }
    return addedStop
  }
  
}

/// :nodoc:
extension TKAPIToCoreDataConverter {
  
  static func insertNewStopLocation(from model: TKAPI.Stop, into context: NSManagedObjectContext) -> StopLocation {
    let coordinate = TKNamedCoordinate(latitude: model.lat, longitude: model.lng, name: model.name, address: model.services)
    let newStop = StopLocation.insertStop(stopCode: model.code, modeInfo: model.modeInfo, at: coordinate, in: context)
    _ = newStop.update(from: model)
    return newStop
  }

}

// MARK: - Services

/// :nodoc:
extension Service {
  convenience init(from model: TKAPI.Departure, into context: NSManagedObjectContext) {
    self.init(context: context)
//    update(from: model)
//  }
//
//  func update(from model: TKAPI.Service) {
    frequency = model.frequency != nil ? NSNumber(value: model.frequency!) : nil
    number = model.number
    lineName = model.name
    direction = model.direction
    code = model.serviceTripID
    color = model.color?.color
    modeInfo = model.modeInfo
    operatorName = model.operatorName
    wheelchairAccessibility = TKWheelchairAccessibility(bool: model.wheelchairAccessible)
    
    isBicycleAccessible = model.bicycleAccessible ?? false
    alertHashCodes = model.alertHashCodes?.map { NSNumber(value: $0) }
    
    adjustRealTimeStatus(for: model.realTimeStatus ?? .incapable)
    addVehicles(primary: model.primaryVehicle, alternatives: model.alternativeVehicles)
  }
  
  func adjustRealTimeStatus(for status: TKAPI.RealTimeStatus) {
    switch status {
    case .isRealTime:
      isRealTime = true
      isRealTimeCapable = true
      isCanceled = false
    case .canceled:
      isRealTime = true
      isRealTimeCapable = true
      isCanceled = true
    case .capable:
      isRealTime = false
      isRealTimeCapable = true
      isCanceled = false
    case .incapable:
      isRealTime = false
      isRealTimeCapable = false
      isCanceled = false
    }
  }
  
  @discardableResult
  func addVisits<E: StopVisits>(_ visitType: E.Type, from model: TKAPI.Departure, at stop: StopLocation) -> E? {
    guard let context = managedObjectContext else { return nil }
    
    let visit = E(context: context)

    // Prefer real-time data all fall back to timetable data
    if let departure = (model.realTimeDeparture ?? model.startTime) {
      visit.departure = Date(timeIntervalSince1970: departure)
      visit.triggerRealTimeKVO()
    }
    if let arrival = (model.realTimeArrival ?? model.endTime) {
      visit.arrival = Date(timeIntervalSince1970: arrival)
    }
    
    // Keep timetable data indicate whether a service is on-time
    if let timetable = model.startTime {
      visit.originalTime = Date(timeIntervalSince1970: timetable)
    }
    
    visit.searchString = model.searchString
    visit.service = self
    visit.stop = stop
    
    // need to do this after setting stop
    visit.adjustRegionDay()
    
    return visit
  }
  
  func addVehicles(primary: TKAPI.Vehicle?, alternatives: [TKAPI.Vehicle]?) {
    guard let context = managedObjectContext else { return }

    if let primary = primary {
      if let existing = vehicle {
        existing.update(with: primary)
      } else {
        vehicle = Vehicle(from: primary, into: context)
      }
      // not updating `isRealTime` here as that's related to times
      self.isRealTimeCapable = true
      self.isCanceled = false
    }
    
    if let alternatives = alternatives {
      for model in alternatives {
        let existing = vehicleAlternatives?.first { $0.identifier == model.id }
        if let vehicle = existing {
          vehicle.update(with: model)
        } else {
          addVehicleAlternativesObject(Vehicle(from: model, into: context))
        }
      }
      self.isRealTimeCapable = true
    }
  }
}

/// :nodoc:
extension TKAPIToCoreDataConverter {
  @objc(updateVehiclesForService:primaryVehicle:alternativeVehicles:)
  public static func updateVehicles(for service: Service, primaryVehicle: [String: Any]?, alternativeVehicles: [[String: Any]]?) {
    let decoder = JSONDecoder()
    
    var primary: TKAPI.Vehicle? = nil
    if let dict = primaryVehicle, let model = try? decoder.decode(TKAPI.Vehicle.self, withJSONObject: dict) {
      primary = model
    }
    
    var alternatives: [TKAPI.Vehicle]? = nil
    if let array = alternativeVehicles, let model = try? decoder.decode([TKAPI.Vehicle].self, withJSONObject: array) {
      alternatives = model
    }
    
    service.addVehicles(primary: primary, alternatives: alternatives)
  }
  
}

// MARK: - Alerts

/// :nodoc:
extension Alert {
  
  convenience init(from model: TKAPI.Alert, into context: NSManagedObjectContext) {
    self.init(context: context)
    
    hashCode = NSNumber(value: model.hashCode)
    title = model.title
    startTime = model.fromDate
    endTime = model.toDate
    if let location = model.location {
      self.location = TKNamedCoordinate(from: location)
    }
    switch model.severity {
    case .alert: alertSeverity = .alert
    case .warning: alertSeverity = .warning
    case .info: alertSeverity = .info
    }
    remoteIcon = model.remoteIcon?.absoluteString
    
    idService = model.serviceTripID
    url = model.url?.absoluteString
  
    update(from: model)
  }

  func update(from model: TKAPI.Alert) {
    // only takes things we deem dynamic
    text = model.text
    
    if let actionType = model.action?.type {
      switch actionType {
      case .reroute(let stopsToAvoid):
        self.action = [ActionTypeIdentifier.excludingStopsFromRouting: stopsToAvoid]
      }
    }
  }
  
}

/// :nodoc:
extension TKAPIToCoreDataConverter {
  
  static func updateOrAddAlerts(_ alerts: [TKAPI.Alert]?, in context: NSManagedObjectContext) {
    guard let alerts = alerts else { return }
    for alertModel in alerts {
      // first we check if have the alert already
      if let existing = Alert.fetch(withHashCode: NSNumber(value: alertModel.hashCode), inTripKitContext: context) {
    
        existing.update(from: alertModel)
      } else {
        _ = Alert(from: alertModel, into: context)
      }
    }
  }
  
  @objc(updateOrAddAlerts:inTripKitContext:)
  public static func updateOrAddAlerts(from array: [[String: Any]]?, in context: NSManagedObjectContext) {
    guard let array = array else { return }
    let decoder = JSONDecoder()
    let model = try? decoder.decode([TKAPI.Alert].self, withJSONObject: array)
    self.updateOrAddAlerts(model, in: context)
  }
  
}

// MARK: - Vehicles

/// :nodoc:
extension Vehicle {
  
  fileprivate convenience init(from model: TKAPI.Vehicle, into context: NSManagedObjectContext) {
    self.init(context: context)
    update(with: model)
  }
  
  fileprivate func update(with model: TKAPI.Vehicle) {
    identifier = model.id
    label = model.label
    icon = model.icon?.absoluteString
    components = model.components
    
    if let lastUpdated = model.lastUpdate {
      lastUpdate = Date(timeIntervalSince1970: lastUpdated)
    } else {
      assertionFailure("Vehicle is missing last update. Falling back to now.")
      lastUpdate = Date()
    }
    
    latitude = NSNumber(value: model.location.lat)
    longitude = NSNumber(value: model.location.lng)
    if let bearing = model.location.bearing {
      self.bearing = NSNumber(value: bearing)
    }
  }
  
  fileprivate convenience init(dict: [String: Any], into context: NSManagedObjectContext) throws {
    let decoder = JSONDecoder()
    let model = try decoder.decode(TKAPI.Vehicle.self, withJSONObject: dict)
    self.init(from: model, into: context)
  }
  
  fileprivate func update(with dict: [String: Any]) throws {
    let decoder = JSONDecoder()
    let model = try decoder.decode(TKAPI.Vehicle.self, withJSONObject: dict)
    update(with: model)
  }
  
}

/// :nodoc:
extension TKAPIToCoreDataConverter {

  @objc(insertNewVehicle:inTripKitContext:)
  public static func insertNewVehicle(from dict: [String: Any], into context: NSManagedObjectContext) -> Vehicle? {
    return try? Vehicle(dict: dict, into: context)
  }
  
  
  @objc(updateVehicle:fromDictionary:)
  public static func update(vehicle: Vehicle, from dict: [String: Any]) {
    try? vehicle.update(with: dict)
  }
  
  @objc(vehiclesPayloadForVehicles:)
  public static func vehiclesPayload(for vehicles: [TKVehicular]) -> [[String: Any]] {
    return vehicles.map(TKVehicularHelper.skedGoFullDictionary(forVehicle:))
  }
  
}
