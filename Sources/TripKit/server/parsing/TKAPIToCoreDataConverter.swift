//
//  TKAPIToCoreDataConverter.swift
//  TripKit
//
//  Created by Adrian Schoenig on 17/10/16.
//
//

import Foundation
import CoreData

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
    zoneID = model.zoneID
    
    if let popularity = model.popularity {
      sortScore = NSNumber(value: popularity)
    }

    self.wheelchairAccessibility = TKWheelchairAccessibility(bool: model.wheelchairAccessible)

    location = TKNamedCoordinate(latitude: model.lat, longitude: model.lng, name: model.name, address: model.services)
    stopModeInfo = model.modeInfo
    
    var addedStop = false
    if !model.children.isEmpty {
      let lookup = Dictionary(grouping: children ?? []) {
        $0.stopCode
      }
      for newChild in model.children {
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
    alertHashCodes = model.alertHashCodes.map(NSNumber.init)
    
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
      visit.departure = departure
    }
    if let arrival = (model.realTimeArrival ?? model.endTime) {
      visit.arrival = arrival
    }
    
    // Keep timetable data indicate whether a service is on-time
    if let timetable = model.startTime {
      visit.originalTime = timetable
    }
    
    visit.searchString = model.searchString
    visit.startPlatform = model.startPlatform
    visit.timetableStartPlatform = model.timetableStartPlatform
    
    if let dls = visit as? DLSEntry {
      dls.endPlatform = model.endPlatform
      dls.timetableEndPlatform = model.timetableEndPlatform
    }

    visit.service = self
    visit.stop = stop
    
    // need to do this after setting stop
    visit.adjustRegionDay()

    // do this last, as it can trigger other things are the visit
    // would not be consistent earlier.
    visit.triggerRealTimeKVO()
    
    return visit
  }
  
  func addVehicles(primary: TKAPI.Vehicle?, alternatives: [TKAPI.Vehicle]) {
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
    
    if !alternatives.isEmpty {
      for model in alternatives {
        let existing = vehicleAlternatives?.first { $0.identifier == model.id }
        if let vehicle = existing {
          vehicle.update(with: model)
        } else {
          addToVehicleAlternatives(Vehicle(from: model, into: context))
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
    
    var alternatives: [TKAPI.Vehicle] = []
    if let array = alternativeVehicles, let model = try? decoder.decode([TKAPI.Vehicle].self, withJSONObject: array) {
      alternatives = model
    }
    
    service.addVehicles(primary: primary, alternatives: alternatives)
  }
  
}

// MARK: - Shapes

extension Shape {
  
  @discardableResult
  static func insertNewShapes(from model: [TKAPI.SegmentShape], for service: Service?, relativeTime: Date? = nil, modeInfo: TKModeInfo?, context: NSManagedObjectContext? = nil, clearRealTime: Bool) -> [Shape] {
    
    guard let context = context ?? service?.managedObjectContext else {
      assertionFailure("Insert into where exactly...?")
      return []
    }
    
    var added: [Shape] = []
    var groupCount = 0
    var index = 0
    var previous: Service? = nil
    
    for apiShape in model {
      guard !apiShape.encodedWaypoints.isEmpty else { continue }
      
      // Populating the service as we go
      let current: Service?
      if let code = apiShape.serviceTripID, let previous = previous, previous.code != code {
        if let requested = service, code == requested.code {
          current = requested
        } else {
          current = Service.fetchOrInsert(code: code, in: context)
        }
      } else if let requested = service {
        current = requested
      } else {
        current = nil
      }
      if let service = current {
        service.code = apiShape.serviceTripID ?? service.code
        service.color = apiShape.serviceColor?.color ?? service.color
        service.frequency = apiShape.frequency.map(NSNumber.init) ?? service.frequency
        service.lineName = apiShape.lineName ?? service.lineName
        service.direction = apiShape.direction ?? service.direction
        service.number = apiShape.number ?? service.number
        service.modeInfo = modeInfo ?? apiShape.modeInfo ?? service.modeInfo
        service.wheelchairAccessibility = TKWheelchairAccessibility(bool: apiShape.wheelchairAccessible)
        service.isBicycleAccessible = apiShape.bicycleAccessible
        
        if previous != service {
          service.progenitor = previous
        }
        if clearRealTime {
          service.isRealTime = false
        }
      }
      
      // New shape, also for non-PT
      let shape = Shape(context: context)
      shape.index = Int16(groupCount)
      groupCount += 1
      shape.title = apiShape.name
      shape.encodedWaypoints = apiShape.encodedWaypoints
      shape.isDismount = apiShape.dismount
      shape.isHop = apiShape.hop
      shape.metres = apiShape.metres.map(NSNumber.init)
      shape.setSafety(apiShape.safe)
      shape.instruction = apiShape.instruction?.tkInstruction
      shape.roadTags = apiShape.roadTags
      shape.travelled = apiShape.travelled
      
      if apiShape.travelled {
        // we only associate the travelled section here, which isn't great
        // but better than only associating the last one...
        current?.shape = shape
      }
      
      // add the stops
      if let service = current {
        // remember the existing visits
        var existingVisitsByCode: [String: StopVisits] = [:]
        let visits = (current?.visits ?? []).filter { !($0 is DLSEntry) }
        for visit in visits {
          existingVisitsByCode[visit.stop.stopCode] = visit
        }
        
        for apiStop in apiShape.stops {
          let visit: StopVisits
          if let existing = existingVisitsByCode[apiStop.code] {
            visit = existing
          } else {
            visit = StopVisits(context: context)
            visit.service = service
          }
          visit.index = Int16(index)
          index += 1
          
          visit.update(from: apiStop, relativeTime: relativeTime)
          
          // hook-up to shape
          shape.addToVisits(visit)
          
          if !existingVisitsByCode.keys.contains(apiStop.code) {
            // We added a new visit; we used to use `fetchOrInsert` but the
            // duplicate checking is remarkably slow :-(
            let coordinate = TKNamedCoordinate(latitude: apiStop.lat, longitude: apiStop.lng, name: apiStop.name, address: nil)
            let stop = StopLocation.insertStop(stopCode: apiStop.code, modeInfo: modeInfo, at: coordinate, in: context)
            stop.shortName = apiStop.shortName
            stop.wheelchairAccessible = apiStop.wheelchairAccessible.map(NSNumber.init)
            assert((visit.stop as StopLocation?) == nil || visit.stop == stop, "We shouldn't have a stop already!")
            visit.stop = stop
          }
          assert((visit.stop as StopLocation?) != nil, "Visit needs a stop!")
        }
      }
        
      added.append(shape)
      if let previous = previous, let current = current, current != previous {
        index = 0
      }
      previous = current
    }
    
    return added
  }
  
}

extension TKAPI.ShapeInstruction {
  fileprivate var tkInstruction: Shape.Instruction {
    switch self {
    case .headTowards: return .headTowards
    case .continueStraight: return .continueStraight
    case .turnSlightyLeft: return .turnSlightyLeft
    case .turnLeft: return .turnLeft
    case .turnSharplyLeft: return .turnSharplyLeft
    case .turnSlightlyRight: return .turnSlightlyRight
    case .turnRight: return .turnRight
    case .turnSharplyRight: return .turnSharplyRight
    }
  }
}

// MARK: - Stop Visits

extension StopVisits {
  func update(from model: TKAPI.ShapeStop, relativeTime: Date?) {
    precondition((service as Service?) != nil)
    precondition((index as NSNumber?) != nil)
    precondition(index >= 0)
    
    // when we re-use an existing visit, we need to be conservative
    // as to not overwrite a previous arrival/departure with a new 'nil'
    // value. this can happen, say, with the 555 loop where 'circular quay'
    // is both the first and last stop. we don't want to overwrite the
    // initial departure with the nil value when the service gets back there
    // at the end of its loop.
    if let bearing = model.bearing {
      self.bearing = NSNumber(value: bearing)
    }
    
    if let arrival = model.arrival {
      self.arrival = arrival
    } else if let offset = model.relativeArrival, let arrival = relativeTime?.addingTimeInterval(offset) {
      self.arrival = arrival
    }

    if let departure = model.departure {
      self.departure = departure
    } else if let offset = model.relativeDeparture, let departure = relativeTime?.addingTimeInterval(offset) {
      self.departure = departure
    }

    guard arrival != nil || departure != nil else {
      return
    }
    
    triggerRealTimeKVO()
      
    // keep original time before we touch it with real-time data
    originalTime = departure ?? arrival

    // frequency-based entries don't have times, so they don't have a region-day either
    adjustRegionDay()
  }
}

// MARK: - Alerts

/// :nodoc:
extension Alert {
  
  convenience init(from model: TKAPI.Alert, into context: NSManagedObjectContext) {
    self.init(context: context)
    
    hashCode = Int32(model.hashCode)
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

extension TKAPIToCoreDataConverter {
  
  static func updateOrAddAlerts(_ alerts: [TKAPI.Alert]?, in context: NSManagedObjectContext) {
    guard let alerts = alerts else { return }
    for alertModel in alerts {
      // first we check if have the alert already
      if let existing = Alert.fetch(hashCode: NSNumber(value: alertModel.hashCode), in: context) {
    
        existing.update(from: alertModel)
      } else {
        _ = Alert(from: alertModel, into: context)
      }
    }
  }
  
}

// MARK: - Vehicles

/// :nodoc:
extension Vehicle {
  
  public convenience init(from model: TKAPI.Vehicle, into context: NSManagedObjectContext) {
    self.init(context: context)
    update(with: model)
  }
  
  func update(with model: TKAPI.Vehicle) {
    identifier = model.id
    label = model.label
    icon = model.icon?.absoluteString
    components = model.components
    
    if let lastUpdated = model.lastUpdate {
      lastUpdate = Date(timeIntervalSince1970: lastUpdated)
    } else {
      lastUpdate = Date()
    }
    
    latitude = model.location.lat
    longitude = model.location.lng
    if let bearing = model.location.bearing {
      self.bearing = NSNumber(value: bearing)
    }
  }
  
}

// MARK: - Private vehicles

extension TKVehicular {
  
  private var privateVehicleType: TKAPI.PrivateVehicleType {
    switch vehicleType() {
    case .bicycle: return .bicycle
    case .motorbike: return .motorbike
    case .SUV: return .SUV
    default: return .car
    }
  }
  
  public func toModel() -> TKAPI.PrivateVehicle {
    return TKAPI.PrivateVehicle(
      type: privateVehicleType,
      UUID: vehicleUUID?() ?? nil,
      name: name(),
      garage: TKAPI.Location(annotation: garage?())
    )
  }
}


extension TKAPIToCoreDataConverter {
  
  public static func vehiclesModel(for vehicles: [TKVehicular]) -> [TKAPI.PrivateVehicle] {
    return vehicles.map { $0.toModel() }
  }

  
  @objc(vehiclesPayloadForVehicles:)
  public static func vehiclesPayload(for vehicles: [TKVehicular]) -> [[String: Any]] {
    let model = vehiclesModel(for: vehicles)
    do {
      return (try JSONEncoder().encodeJSONObject(model) as? [[String: Any]]) ?? []
    } catch {
      assertionFailure()
      return []
    }
  }
  
}
