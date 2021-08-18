//
//  TKRoutingParser.swift
//  TripKit
//
//  Created by Adrian Schönig on 10/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import CoreData

public final class TKRoutingParser {
  
  private init() {}
  
  enum ParserError: Error {
    case didNotFinish
    case mismatchingResponse
    case serverError(String)
  }
  
  public static func add(_ response: TKAPI.RoutingResponse, into context: NSManagedObjectContext = TripKit.shared.tripKitContext, completion: @escaping (Result<TripRequest, Error>) -> Void) {
    context.perform {
      let request = TripRequest(context: context)
      request.timeCreated = .init()
      do {
        try add(response,
                mode: .addTo(request),
                context: context,
                allowDuplicates: true,
                visibility: .full
        )
        
        Self.populate(request, using: response.query)
        completion(.success(request))
        
      } catch {
        context.delete(request)
        completion(.failure(error))
      }
    }
  }
  
  static func addBlocking(_ response: TKAPI.RoutingResponse, into context: NSManagedObjectContext) throws -> TripRequest {
    var result: Result<TripRequest, Error>? = nil
    context.performAndWait {
      let request = TripRequest(context: context)
      request.timeCreated = .init()
      result = Result {
        try add(response,
                mode: .addTo(request),
                context: context,
                allowDuplicates: true,
                visibility: .full
        )
        
        Self.populate(request, using: response.query)
        return request
      }
    }
    return try result.orThrow(ParserError.didNotFinish).get()
  }
  
  static func add(_ response: TKAPI.RoutingResponse, to request: TripRequest, merge: Bool, visibility: TripGroup.Visibility = .full, completion: @escaping (Result<[Trip], Error>) -> Void) {
    guard let context = request.managedObjectContext else {
      assertionFailure("Request's context went missing.")
      completion(.success([]))
      return
    }
    
    context.perform {
      do {
        let added = try add(response,
                mode: .addTo(request),
                context: context,
                allowDuplicates: !merge,
                visibility: visibility
        )
        completion(.success(added))
        
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  static func add(_ response: TKAPI.RoutingResponse, to group: TripGroup, merge: Bool, completion: @escaping (Result<[Trip], Error>) -> Void) {
    guard let context = group.managedObjectContext else {
      assertionFailure("Trip group's context went missing.")
      completion(.success([]))
      return
    }
    
    context.perform {
      do {
        let added = try add(response,
                mode: .appendTo(group),
                context: context,
                allowDuplicates: !merge,
                visibility: .full
        )
        completion(.success(added))
        
      } catch {
        completion(.failure(error))
      }
    }
  }
  
  static func update(_ trip: Trip, from response: TKAPI.RoutingResponse, completion: @escaping (Result<Trip, Error>) -> Void) {
    guard let context = trip.managedObjectContext else {
      assertionFailure("Trip's context went missing.")
      completion(.success(trip))
      return
    }
    
    context.perform {
      completion(Result {
        try add(response,
            mode: .update(trip),
            context: context,
            allowDuplicates: true, // we don't actually create a duplicate
            visibility: .full
        )
        try context.save()
        return trip
      })
    }
  }
  
  public static func add<Key>(groups: [Key: [TKAPI.TripGroup]], templates: [TKAPI.SegmentTemplate], alerts: [TKAPI.Alert], into context: NSManagedObjectContext = TripKit.shared.tripKitContext, completion: @escaping (Result<[Key: [Trip]], Error>) -> Void) {
    context.perform {
      do {
        var keyToTrips: [Key: [Trip]] = [:]
        for (key, groups) in groups {
          let request = TripRequest(context: context)
          request.timeCreated = .init()
          let trips = try add(groups: groups, templates: templates, alerts: alerts, mode: .addTo(request), context: context, allowDuplicates: true, visibility: .full)
          if !trips.isEmpty {
            keyToTrips[key] = trips
          }
        }
        completion(.success(keyToTrips))
      } catch {
        completion(.failure(error))
      }
    }
  }

  @discardableResult
  private static func add(
    _ response: TKAPI.RoutingResponse,
    mode: ParseMode,
    context: NSManagedObjectContext,
    allowDuplicates: Bool,
    visibility: TripGroup.Visibility
  ) throws -> [Trip] {
    
    if let error = response.error {
      throw ParserError.serverError(error)
    }
    
    guard
      let groups = response.groups,
      let templates = response.segmentTemplates
    else {
      throw ParserError.mismatchingResponse
    }
    
    return try add(groups: groups, templates: templates, alerts: response.alerts, mode: mode, context: context, allowDuplicates: allowDuplicates, visibility: visibility)
  }

  private enum ParseMode {
    case addTo(TripRequest)
    case appendTo(TripGroup)
    case update(Trip)
    
    var request: TripRequest {
      switch self {
      case .addTo(let request): return request
      case .appendTo(let group): return group.request
      case .update(let trip): return trip.request
      }
    }
    
    var isUpdate: Bool {
      switch self {
      case .update: return true
      case .addTo, .appendTo: return false
      }
    }
  }
  
  private static func add(
    groups: [TKAPI.TripGroup],
    templates: [TKAPI.SegmentTemplate],
    alerts: [TKAPI.Alert],
    mode: ParseMode,
    context: NSManagedObjectContext,
    allowDuplicates: Bool,
    visibility: TripGroup.Visibility
  ) throws -> [Trip] {
    
    let request = mode.request
    guard request.managedObjectContext != nil, !request.isDeleted else {
      return []
    }

    // We want to maintain these and reset to it at the very end
    let originalVisibility: TripGroup.Visibility
    switch mode {
    case .update(let trip): originalVisibility = trip.tripGroup.visibility
    default: originalVisibility = .full
    }
    
    // At first, we need to parse the segment templates, since the trips will reference them
    var templateByHashCodes: [Int: TKAPI.SegmentTemplate] = [:]
    var existingTemplateHashCodes = Set<Int>()
    for apiTemplate in templates {
      templateByHashCodes[apiTemplate.hashCode] = apiTemplate
      if SegmentTemplate.segmentTemplate(withHashCode: apiTemplate.hashCode, existsIn: context) {
        existingTemplateHashCodes.insert(apiTemplate.hashCode)
      }
    }
    
    // Persist the alerts
    TKAPIToCoreDataConverter.updateOrAddAlerts(alerts, in: context)
    
    // Now we create the trips
    let previousTrips = request.trips
    var tripsToReturn: [Trip] = []
    for apiGroup in groups {
      var newTrips = Set<Trip>()
      
      for apiTrip in apiGroup.trips {
        let trip: Trip
        var unmatchedSegmentReferencesByHashCode: [Int: SegmentReference] = [:]
        switch mode {
        case .update(let existing):
          trip = existing
          if let references = existing.segmentReferences {
            unmatchedSegmentReferencesByHashCode = Dictionary(uniqueKeysWithValues: references.map { ($0.templateHashCode?.intValue ?? 0, $0) })
          }
        case .addTo, .appendTo:
          trip = Trip(context: context)
        }
        
        trip.departureTime = apiTrip.depart
        trip.arrivalTime = apiTrip.arrive
        trip.calculateDuration()
        
        trip.mainSegmentHashCode = Int32(apiTrip.mainSegmentHashCode)
        trip.totalCalories = Float(apiTrip.caloriesCost)
        trip.totalCarbon = Float(apiTrip.carbonCost)
        trip.totalHassle = Float(apiTrip.hassleCost)
        trip.totalScore = Float(apiTrip.weightedScore)
        
        // fallback to old values (if we're updating)
        trip.totalPrice = apiTrip.moneyCost.map(NSNumber.init) ?? trip.totalPrice
        trip.update(\.totalPrice, value: apiTrip.moneyCost)
        trip.update(\.totalPriceUSD, value: apiTrip.moneyCostUSD)
        trip.update(\.currencyCode, value: apiTrip.currency)
        trip.update(\.saveURLString, value: apiTrip.saveURL?.absoluteString)
        trip.update(\.shareURLString, value: apiTrip.shareURL?.absoluteString)
        trip.update(\.temporaryURLString, value: apiTrip.temporaryURL?.absoluteString)
        trip.update(\.updateURLString, value: apiTrip.updateURL?.absoluteString)
        trip.update(\.progressURLString, value: apiTrip.progressURL?.absoluteString)
        trip.update(\.plannedURLString, value: apiTrip.plannedURL?.absoluteString)
        trip.update(\.logURLString, value: apiTrip.logURL?.absoluteString)
        trip.update(\.bundleId, value: apiTrip.bundleId)
        
        switch apiTrip.availability {
        case .missedPrebookingWindow: trip.missedBookingWindow = true
        case .canceled: trip.isCanceled = true
        case .none: break
        }
        
        // updated trip isn't strictly speaking new, but we want to process it
        // as a successful match.
        newTrips.insert(trip)
        
        for (index, apiReference) in apiTrip.segments.enumerated() {
          let hashCode = apiReference.segmentTemplateHashCode
          guard let apiTemplate = templateByHashCodes[hashCode] else {
            assertionFailure("Missing template for \(hashCode)")
            continue
          }
          let isNewTemplate = !existingTemplateHashCodes.contains(hashCode)
          
          var reference: SegmentReference! = nil
          if mode.isUpdate {
            if let existing = unmatchedSegmentReferencesByHashCode.removeValue(forKey: hashCode)  {
              reference = existing
            } else {
              trip.clearSegmentCaches()
            }
          }
          if reference == nil, (isNewTemplate || SegmentTemplate.segmentTemplate(withHashCode: hashCode, existsIn: context)) {
            reference = SegmentReference(context: context)
          }
          guard let reference = reference else {
            continue
          }
          
          reference.templateHashCode = NSNumber(value: hashCode)
          reference.startTime = apiReference.startTime
          reference.endTime = apiReference.endTime
          reference.timesAreRealTime = apiReference.timesAreRealTime
          reference.alertHashCodes = apiReference.alertHashCodes.map(NSNumber.init)
          reference.populate(from: apiReference)
          
          let maybeService: Service?
          if let tripID = apiReference.serviceTripID {
            // Public transport
            let service = Service.fetchOrInsert(code: tripID, in: context)
            maybeService = service
            
            // always update these as those might be new or updated, as long as they didn't get deleted
            service.color = apiReference.serviceColor?.color ?? service.color
            service.frequency = apiReference.frequency.map(NSNumber.init) ?? service.frequency
            service.lineName = apiReference.lineName ?? service.lineName
            service.direction = apiReference.direction ?? service.direction
            service.number = apiReference.number ?? service.number
            reference.service = service
            
            reference.bicycleAccessible = apiReference.bicycleAccessible
            reference.wheelchairAccessibility = TKWheelchairAccessibility(bool: apiReference.wheelchairAccessible)
            
            // If we have any time-tabled service, the whole trip is timetabled
            if service.frequency == nil {
              trip.departureTimeIsFixed = true
            }
            
            service.adjustRealTimeStatus(for: apiReference.realTimeStatus ?? .incapable)
            service.addVehicles(primary: apiReference.realTimeVehicle, alternatives: apiReference.realTimeVehicleAlternatives)
            
          } else {
            // Non-PT
            if let apiVehicle = apiReference.realTimeVehicle {
              if let existing = reference.realTimeVehicle {
                existing.update(with: apiVehicle)
              } else {
                reference.realTimeVehicle = Vehicle(from: apiVehicle, into: context)
              }
            }
            maybeService = nil
          }
          
          // Finally, insert the template that this reference points to
          if isNewTemplate {
            SegmentTemplate.insertNewTemplate(from: apiTemplate, for: maybeService, relativeTime: apiReference.startTime, into: context)
            existingTemplateHashCodes.insert(hashCode)
          } else if let service = maybeService {
            // We don't need to insert the full template, but need to add
            // shapes for that service
            
            let modeInfo = service.modeInfo // *not* using `findModeInfo` as we
                        // might have just created this, and it'll get populated
                        // from `apiTemplate`
            SegmentTemplate.insertNewShapes(from: apiTemplate, for: service, relativeTime: reference.startTime, modeInfo: modeInfo, context: context)
          }
          
          reference.index = Int16(index)
          reference.trip = trip
        }
        
        // Clean-up unmatched references
        if !unmatchedSegmentReferencesByHashCode.isEmpty {
          _ = unmatchedSegmentReferencesByHashCode.values.map(context.delete(_:))
        }
        assert((trip.segmentReferences ?? []).count > 0, "Trip has no segments: \(trip)")
      }
      
      if !newTrips.isEmpty {
        var existingGroup: TripGroup? = nil
        var addedTrips: [Trip] = []
        
        // Check if we already have a similar route. If so, we'll add ALL routes of this group to the group of an existing route.
        for trip in newTrips {
          guard request.context != nil, !request.isDeleted else {
            return []
          }

          let existingSimilarTrip = allowDuplicates
            ? nil
            : Trip.findSimilarTrip(to: trip, in: previousTrips)
          if let similar = existingSimilarTrip {
            // remember group, but don't add it
            existingGroup = similar.tripGroup
            tripsToReturn.append(similar)
            if similar != trip {
              context.delete(trip)
            }
          } else {
            addedTrips.append(trip)
            tripsToReturn.append(trip)
          }
        }
        
        switch mode {
        case .appendTo(let group): existingGroup = group
        case .update(let trip): existingGroup = trip.tripGroup
        case .addTo: break
        }
        
        if !addedTrips.isEmpty {
          let tripGroup: TripGroup
          if let existing = existingGroup {
            tripGroup = existing
          } else {
            tripGroup = TripGroup(context: context)
            tripGroup.request = request
          }
          tripGroup.visibility = visibility
          tripGroup.frequency = apiGroup.frequency.map(NSNumber.init) ?? tripGroup.frequency
          tripGroup.sources = apiGroup.sources
          newTrips
            .filter { $0.managedObjectContext != nil }
            .forEach { $0.tripGroup = tripGroup }
          
          if !mode.isUpdate {
            tripGroup.adjustVisibleTrip()
          }
        }
      }
    }
    
    // restore visibility
    switch mode {
    case .update(let trip): trip.tripGroup.visibility = originalVisibility
    default: break
    }
    
    return tripsToReturn
  }
  
}

extension Trip {
  func update<V>(_ path: WritableKeyPath<Trip, V>, value: V?) {
    guard let value = value else { return }
    var trip = self
    trip[keyPath: path] = value
  }
  
  func update(_ path: WritableKeyPath<Trip, NSNumber?>, value: Double?) {
    guard let value = value else { return }
    var trip = self
    trip[keyPath: path] = NSNumber(value: value)
  }
}
