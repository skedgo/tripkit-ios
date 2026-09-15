//
//  TKRealTimeFetcher.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(CoreData)

import Foundation
import CoreData

public class TKRealTimeFetcher {
  private init() {}

  static func latestParameters(for visit: StopVisits) -> (service: Service, parameters: [String: Any])? {
    guard let service = visit.service, service.isRealTimeCapable, let startTime = visit.originalTime else { return nil }
    return (
      service,
      [
        "serviceTripID": service.code,
        "operatorID": service.operatorID ?? "",
        "operator": service.operatorName ?? "",
        "startStopCode": visit.stop.stopCode,
        "startTime": startTime.timeIntervalSince1970,
      ]
    )
  }
  
  static func latestParameters(for entry: DLSEntry) -> (service: Service, parameters: [String: Any])? {
    guard let service = entry.service, service.isRealTimeCapable, let startTime = entry.originalTime else { return nil }
    return (
      service,
      [
        "serviceTripID": service.code,
        "operatorID": service.operatorID ?? "",
        "operator": service.operatorName ?? "",
        "startStopCode": entry.stop.stopCode,
        "startTime": startTime.timeIntervalSince1970,
        "endStopCode": entry.endStop.stopCode,
      ]
    )
  }
  
  /// The `serviceParas` to post, paired with what each answered service should update.
  struct Updateables {
    var serviceParas: [[String: Any]] = []
    /// Keyed by `Service.code`; a value per updateable, since one service can appear at several stops.
    var byServiceCode: [String: [Updateable]] = [:]
    var context: NSManagedObjectContext? = nil

    mutating func add(_ parameters: [String: Any], for service: Service, updating updateable: Updateable) {
      context = context ?? service.managedObjectContext
      assert(context == service.managedObjectContext)
      serviceParas.append(parameters)
      byServiceCode[service.code, default: []].append(updateable)
    }
  }

  static func updateables(for entries: Set<DLSEntry>) -> Updateables {
    var result = Updateables()
    for entry in entries {
      guard let latest = latestParameters(for: entry) else { continue }
      result.add(latest.parameters, for: latest.service, updating: .visit(entry))
    }
    return result
  }

  static func updateables(for visits: Set<StopVisits>) -> Updateables {
    var result = Updateables()
    for visit in visits {
      guard let latest = latestParameters(for: visit) else { continue }
      result.add(latest.parameters, for: latest.service, updating: .visit(visit))
    }
    return result
  }

  static func updateables(for services: Set<Service>) -> Updateables {
    var result = Updateables()
    for service in services {
      guard service.wantsRealTimeUpdates else { continue }
      result.add([
        "serviceTripID": service.code,
        "operatorID": service.operatorID ?? "",
        "operator": service.operatorName ?? "",
      ], for: service, updating: .service(service))
    }
    return result
  }

  @MainActor
  public static func update(_ entries: Set<DLSEntry>, in region: TKRegion) async throws -> Set<DLSEntry> {
    try await fetchAndUpdate(updateables(for: entries), region: region)
    return entries
  }
  
  @MainActor
  public static func update(_ visits: Set<StopVisits>, in region: TKRegion) async throws -> Set<StopVisits> {
    try await fetchAndUpdate(updateables(for: visits), region: region)
    return visits
  }
  
  @MainActor
  public static func update(_ services: Set<Service>, in region: TKRegion) async throws -> Set<Service> {
    try await fetchAndUpdate(updateables(for: services), region: region)
    return services
  }

  @MainActor
  private static func fetchAndUpdate(
    _ updateables: Updateables,
    region: TKRegion
  ) async throws {
    guard !updateables.serviceParas.isEmpty, let context = updateables.context else {
      return
    }
    
    let paras: [String: Any] = [
      "region": region.code,
      "block": false,
      "services": updateables.serviceParas
    ]
    
    let response = await TKServer.shared.hit(TKAPI.LatestResponse.self, .POST, path: "latest.json", parameters: paras, region: region)
    let content = try response.result.get()
    await context.perform {
      update(updateables: updateables, from: content)
    }
  }
  
  enum Updateable {
    case visit(StopVisits)
    case service(Service)

    /// The server returns one entry per requested `startStopCode`, all sharing a `serviceTripID`,
    /// so an entry that names a stop may only be applied to the visit at that stop.
    func covers(stopCode: String) -> Bool {
      switch self {
      case .visit(let visit): return visit.stop?.stopCode == stopCode
      case .service: return true
      }
    }
  }
  
  @MainActor
  static func update(updateables: Updateables, from response: TKAPI.LatestResponse) {
    for apiService in response.services {
      guard let candidates = updateables.byServiceCode[apiService.code] else {
        continue
      }
      let updatables = apiService.startStopCode.map { stopCode in
        candidates.filter { $0.covers(stopCode: stopCode) }
      } ?? candidates
      
      for updatable in updatables {
      let service: Service
      let visit: StopVisits?
      switch updatable {
      case .visit(let updateable):
        service = updateable.service
        visit = updateable
      case .service(let updateable):
        service = updateable
        visit = nil
      }
      
      service.addVehicles(primary: apiService.primaryVehicle, alternatives: apiService.alternativeVehicles)
      
      if let visit = visit {
        // we have supplied a start stop code, so we only want to update that
        guard let startTime = apiService.startTime else { continue }
        if let dls = visit as? DLSEntry {
          if let endTime = apiService.endTime {
            dls.departure = startTime
            dls.arrival = endTime
            service.isRealTime = true
          } else if let arrival = dls.arrival, let departure = dls.departure {
            let previousDuration = arrival.timeIntervalSince(departure)
            dls.departure = startTime
            dls.arrival = startTime.addingTimeInterval(previousDuration)
            service.isRealTime = true
          }
          
        } else {
          visit.departure = startTime
          visit.triggerRealTimeKVO()
          service.isRealTime = true
        }
      
      } else if !apiService.stops.isEmpty {
        // we want to update all the stops in the service
        service.isRealTime = true
        let arrivals = apiService.stops.reduce(into: [String: Date]()) { acc, next in
          acc[next.stopCode] = next.arrival
        }
        let departures = apiService.stops.reduce(into: [String: Date]()) { acc, next in
          acc[next.stopCode] = next.departure
        }
        
        var delay: TimeInterval = 0
        for visit in service.sortedVisits {
          guard let stopCode = visit.stop?.stopCode else { continue }
          if let newArrival = arrivals[stopCode] {
            if let arrival = visit.arrival {
              delay = newArrival.timeIntervalSince(arrival)
            }
            visit.arrival = newArrival
          }
          if let newDeparture = departures[stopCode] {
            if let departure = visit.departure {
              delay = newDeparture.timeIntervalSince(departure)
            }
            // use time for KVO
            visit.departure = newDeparture
            visit.triggerRealTimeKVO()
          }
          if arrivals[stopCode] == nil, let arrival = visit.arrival, abs(delay) > 1 {
            visit.arrival = arrival.addingTimeInterval(delay)
          }
          if departures[stopCode] == nil, let departure = visit.departure, abs(delay) > 1 {
            // use time for KVO
            visit.departure = departure.addingTimeInterval(delay)
            visit.triggerRealTimeKVO()
          }
        }
      }
      }
    }
  }
  
}

#endif
