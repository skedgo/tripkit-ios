//
//  TKAPIToCoreDataConverter.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation

@objc
public class TKAPIToCoreDataConverter: NSObject {
  override private init() {
    super.init()
  }
}

// MARK: - Stops

extension StopLocation {

  func update(from model: API.Stop) -> Bool {
    guard let context = managedObjectContext else {
      assertionFailure("Stop has no context")
      return false
    }
    
    stopCode  = model.code
    shortName = model.shortName
    
    if let popularity = model.popularity {
      sortScore = NSNumber(value: popularity)
    }
    if let isAccessible = model.wheelchairAccessible {
      wheelchairAccessible = NSNumber(value: isAccessible)
    }
    location = SGKNamedCoordinate(latitude: model.lat, longitude: model.lng, name: model.name, address: model.services)
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

extension TKAPIToCoreDataConverter {
  
  static func insertNewStopLocation(from model: API.Stop, into context: NSManagedObjectContext) -> StopLocation {
    let coordinate = SGKNamedCoordinate(latitude: model.lat, longitude: model.lng, name: model.name, address: model.services)
    let newStop = StopLocation.insertStop(forStopCode: model.code, modeInfo: nil, atLocation: coordinate, intoTripKitContext: context)
    _ = newStop.update(from: model)
    return newStop
  }
  
  @objc(insertNewStopLocation:inTripKitContext:)
  public static func insertNewStopLocation(from dict: [String: Any], into context: NSManagedObjectContext) -> StopLocation? {
    let decoder = JSONDecoder()
    guard let model = try? decoder.decode(API.Stop.self, withJSONObject: dict) else {
      return nil
    }
    return insertNewStopLocation(from: model, into: context)
  }
  
  @objc(updateStopLocation:fromDictionary:)
  @discardableResult
  public static func update(_ stop: StopLocation, from dict: [String: Any]) -> Bool {
    let decoder = JSONDecoder()
    guard let model = try? decoder.decode(API.Stop.self, withJSONObject: dict) else {
      return false
    }
    return stop.update(from: model)
  }
}

// MARK: - Services

extension Service {
  convenience init(from model: API.Departure, into context: NSManagedObjectContext) {
    if #available(iOS 10.0, macOS 10.12, *) {
      self.init(context: context)
    } else {
      self.init(entity: NSEntityDescription.entity(forEntityName: "Service", in: context)!, insertInto: context)
    }
//    update(from: model)
//  }
//
//  func update(from model: API.Service) {
    frequency = model.frequency != nil ? NSNumber(value: model.frequency!) : nil
    number = model.number
    lineName = model.name
    direction = model.direction
    code = model.serviceTripID
    color = model.color?.color
    modeInfo = model.modeInfo
    operatorName = model.operatorName
    isWheelchairAccessible = model.wheelchairAccessible ?? false // FIXME: Should be optional
    isBicycleAccessible = model.bicycleAccessible ?? false
    alertHashCodes = model.alertHashCodes?.map { NSNumber(value: $0) }
    
    adjustRealTimeStatus(for: model.realTimeStatus ?? .incapable)
    addVehicles(primary: model.primaryVehicle, alternatives: model.alternativeVehicles)
  }
  
  func adjustRealTimeStatus(for status: API.RealTimeStatus) {
    switch status {
    case .isRealTime:
      isRealTime = true
      isRealTimeCapable = true
      isCancelled = false
    case .canceled:
      isRealTime = true
      isRealTimeCapable = true
      isCancelled = true
    case .capable:
      isRealTime = false
      isRealTimeCapable = true
      isCancelled = false
    case .incapable:
      isRealTime = false
      isRealTimeCapable = false
      isCancelled = false
    }
  }
  
  @discardableResult
  func addVisits<E: StopVisits>(_ visitType: E.Type, from model: API.Departure, at stop: StopLocation) -> E? {
    guard let context = managedObjectContext else { return nil }
    
    let visit: E
    if #available(iOS 10.0, macOS 10.12, *) {
      visit = E(context: context)
    } else {
      let entityName = (visitType == DLSEntry.self) ? "DLSEntry" : "StopVisits"
      visit = E(entity: NSEntityDescription.entity(forEntityName: entityName, in: context)!, insertInto: context)
    }
    if let start = model.startTime {
      // we use 'time' to allow KVO
      visit.time = Date(timeIntervalSince1970: start)
    }
    if let end = model.endTime {
      visit.arrival = Date(timeIntervalSince1970: end)
    }
    visit.originalTime = visit.time
    visit.searchString = model.searchString
    visit.service = self
    visit.stop = stop
    
    // need to do this after setting stop
    visit.adjustRegionDay()
    
    return visit
  }
  
  func addVehicles(primary: API.Vehicle?, alternatives: [API.Vehicle]?) {
    guard let context = managedObjectContext else { return }

    if let primary = primary {
      if let existing = vehicle {
        existing.update(with: primary)
      } else {
        vehicle = Vehicle(from: primary, into: context)
      }
      // not updating `isRealTime` here as that's related to times
      self.isRealTimeCapable = true
      self.isCancelled = false
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

extension TKAPIToCoreDataConverter {
  @objc(updateVehiclesForService:primaryVehicle:alternativeVehicles:)
  public static func updateVehicles(for service: Service, primaryVehicle: [String: Any]?, alternativeVehicles: [[String: Any]]?) {
    let decoder = JSONDecoder()
    
    var primary: API.Vehicle? = nil
    if let dict = primaryVehicle, let model = try? decoder.decode(API.Vehicle.self, withJSONObject: dict) {
      primary = model
    }
    
    var alternatives: [API.Vehicle]? = nil
    if let array = alternativeVehicles, let model = try? decoder.decode([API.Vehicle].self, withJSONObject: array) {
      alternatives = model
    }
    
    service.addVehicles(primary: primary, alternatives: alternatives)
  }
  
}

// MARK: - Alerts

extension Alert {
  
  convenience init(from model: API.Alert, into context: NSManagedObjectContext) {
    if #available(iOS 10.0, macOS 10.12, *) {
      self.init(context: context)
    } else {
      self.init(entity: NSEntityDescription.entity(forEntityName: "Alert", in: context)!, insertInto: context)
    }
    
    hashCode = NSNumber(value: model.hashCode)
    title = model.title
    startTime = model.fromDate
    endTime = model.toDate
    if let location = model.location {
      self.location = SGKNamedCoordinate(from: location)
    }
    switch model.severity {
    case .alert: alertSeverity = .alert
    case .warning: alertSeverity = .warning
    case .info: alertSeverity = .info
    }
    remoteIcon = model.remoteIcon?.absoluteString
  
    update(from: model)
  }

  func update(from model: API.Alert) {
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

extension TKAPIToCoreDataConverter {
  
  static func updateOrAddAlerts(_ alerts: [API.Alert]?, in context: NSManagedObjectContext) {
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
    let model = try? decoder.decode([API.Alert].self, withJSONObject: array)
    self.updateOrAddAlerts(model, in: context)
  }
  
}

// MARK: - Vehicles

extension Vehicle {
  
  fileprivate convenience init(from model: API.Vehicle, into context: NSManagedObjectContext) {
    if #available(iOS 10.0, macOS 10.12, *) {
      self.init(context: context)
    } else {
      self.init(entity: NSEntityDescription.entity(forEntityName: "Vehicle", in: context)!, insertInto: context)
    }
    update(with: model)
  }
  
  fileprivate func update(with model: API.Vehicle) {
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
    let model = try decoder.decode(API.Vehicle.self, withJSONObject: dict)
    self.init(from: model, into: context)
  }
  
  fileprivate func update(with dict: [String: Any]) throws {
    let decoder = JSONDecoder()
    let model = try decoder.decode(API.Vehicle.self, withJSONObject: dict)
    update(with: model)
  }
  
}

extension TKAPIToCoreDataConverter {

  @objc(insertNewVehicle:inTripKitContext:)
  public static func insertNewVehicle(from dict: [String: Any], into context: NSManagedObjectContext) -> Vehicle? {
    return try? Vehicle(dict: dict, into: context)
  }
  
  
  @objc(updateVehicle:fromDictionary:)
  public static func update(vehicle: Vehicle, from dict: [String: Any]) {
    try? vehicle.update(with: dict)
  }
}

// MARK: - Private vehicles

extension STKVehicular {
  
  private var privateVehicleType: API.PrivateVehicleType {
    switch vehicleType() {
    case .bicycle: return .bicycle
    case .motorbike: return .motorbike
    case .SUV: return .SUV
    default: return .car
    }
  }
  
  public func toModel() -> API.PrivateVehicle {
    return API.PrivateVehicle(
      type: privateVehicleType,
      UUID: vehicleUUID?() ?? nil,
      name: name(),
      garage: API.Location(annotation: garage?())
    )
  }
}


extension TKAPIToCoreDataConverter {
  
  public static func vehiclesModel(for vehicles: [STKVehicular]) -> [API.PrivateVehicle] {
    return vehicles.map { $0.toModel() }
  }
  
  @objc(vehiclesPayloadForVehicles:)
  public static func vehiclesPayload(for vehicles: [STKVehicular]) -> [[String: Any]] {
    let model = vehiclesModel(for: vehicles)
    do {
      return (try JSONEncoder().encodeJSONObject(model) as? [[String: Any]]) ?? []
    } catch {
      assertionFailure()
      return []
    }
  }

}
