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
  
  public static func update(_ entries: Set<DLSEntry>, in region: TKRegion, completion: @escaping (Result<Set<DLSEntry>, Error>) -> Void) {
    var serviceParas: [[String: Any]] = []
    var keysToUpdateables: [String: Updateable] = [:]
    var context: NSManagedObjectContext? = nil
    for entry in entries {
      guard let service = entry.service, !service.wantsRealTimeUpdates, let startTime = entry.originalTime else { continue }
      context = context ?? service.managedObjectContext
      assert(context == service.managedObjectContext)

      serviceParas.append([
        "serviceTripID": service.code,
        "operatorID": service.operatorID ?? "",
        "operator": service.operatorName ?? "",
        "startStopCode": entry.stop.stopCode,
        "startTime": startTime.timeIntervalSince1970,
        "endStopCode": entry.endStop.stopCode,
      ])
      keysToUpdateables[service.code] = .service(service)
    }
    
    fetchAndUpdate(serviceParas: serviceParas, keysToUpdateables: keysToUpdateables, region: region, context: context) { result in
      completion(result.map { _ in entries })
    }
  }
  
  public static func update(_ visits: Set<StopVisits>, in region: TKRegion, completion: @escaping (Result<Set<StopVisits>, Error>) -> Void) {
    var serviceParas: [[String: Any]] = []
    var keysToUpdateables: [String: Updateable] = [:]
    var context: NSManagedObjectContext? = nil
    for visit in visits {
      guard let service = visit.service, !service.wantsRealTimeUpdates, let startTime = visit.originalTime else { continue }
      context = context ?? service.managedObjectContext
      assert(context == service.managedObjectContext)

      serviceParas.append([
        "serviceTripID": service.code,
        "operatorID": service.operatorID ?? "",
        "operator": service.operatorName ?? "",
        "startStopCode": visit.stop.stopCode,
        "startTime": startTime.timeIntervalSince1970,
      ])
      keysToUpdateables[service.code] = .service(service)
    }
    
    fetchAndUpdate(serviceParas: serviceParas, keysToUpdateables: keysToUpdateables, region: region, context: context) { result in
      completion(result.map { _ in visits })
    }
  }
  
  public static func update(_ services: Set<Service>, in region: TKRegion, completion: @escaping (Result<Set<Service>, Error>) -> Void) {
    var serviceParas: [[String: Any]] = []
    var keysToUpdateables: [String: Updateable] = [:]
    var context: NSManagedObjectContext? = nil
    for service in services {
      guard service.wantsRealTimeUpdates else { continue }
      context = context ?? service.managedObjectContext
      assert(context == service.managedObjectContext)

      serviceParas.append([
        "serviceTripID": service.code,
        "operatorID": service.operatorID ?? "",
        "operator": service.operatorName ?? "",
      ])
      keysToUpdateables[service.code] = .service(service)
    }
    
    fetchAndUpdate(serviceParas: serviceParas, keysToUpdateables: keysToUpdateables, region: region, context: context) { result in
      completion(result.map { _ in services })
    }
  }

  private static func fetchAndUpdate(
    serviceParas: [[String: Any]],
    keysToUpdateables: [String: Updateable],
    region: TKRegion,
    context: NSManagedObjectContext?,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard !serviceParas.isEmpty, let context = context else {
      return completion(.success(()))
    }
    
    let paras: [String: Any] = [
      "region": region.name,
      "block": false,
      "services": serviceParas
    ]
    
    TKServer.shared.hit(TKAPI.LatestResponse.self, .POST, path: "latest.json", parameters: paras, region: region, callbackOnMain: false) { _, _, result in
      switch result {
      case .success(let response):
        context.perform {
          update(keysToUpdateables: keysToUpdateables, from: response)
          completion(.success(()))
        }
      case .failure(let error):
        completion(.failure(error))
      }
    }
  }
  
  private enum Updateable {
    case visit(StopVisits)
    case service(Service)
  }
  
  private static func update(keysToUpdateables: [String: Updateable], from response: TKAPI.LatestResponse) {
    
    for apiService in response.services {
      guard let updatable = keysToUpdateables[apiService.code] else {
        continue
      }
      
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
          if let newArrival = arrivals[visit.stop.stopCode] {
            if let arrival = visit.arrival {
              delay = newArrival.timeIntervalSince(arrival)
            }
            visit.arrival = newArrival
          }
          if let newDeparture = departures[visit.stop.stopCode] {
            if let departure = visit.departure {
              delay = newDeparture.timeIntervalSince(departure)
            }
            // use time for KVO
            visit.departure = newDeparture
            visit.triggerRealTimeKVO()
          }
          if arrivals[visit.stop.stopCode] == nil, let arrival = visit.arrival, abs(delay) > 1 {
            visit.arrival = arrival.addingTimeInterval(delay)
          }
          if departures[visit.stop.stopCode] == nil, let departure = visit.departure, abs(delay) > 1 {
            // use time for KVO
            visit.departure = departure.addingTimeInterval(delay)
            visit.triggerRealTimeKVO()
          }
        }
      }
    }
  }
  
}

#endif
