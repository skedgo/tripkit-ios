//
//  TKTTPifier.swift
//  TripKit - AddOns - Agenda
//
//  Created by Adrian Schoenig on 16/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift
import Marshal

extension Error {
  fileprivate func isNotConnectedError() -> Bool {
    return (self as NSError).code == -1009
  }
}

public struct TKTTPifier : TKAgendaBuilderType {
  enum TTPError : Error {
    case creatingProblemFailedOnServer
    case fetchingSolutionFailedOnServer
    case problemNotFoundOnServer
  }
  
  fileprivate static var problemIDs: Set<String> = []
  
  public static func debugDictionary() -> [String: Any]? {
    return [
      "problemIDs": Array(problemIDs),
    ]
  }
  
  public let modes: [String]?
  
  public init(modes: [String]? = nil) {
    self.modes = modes
  }
  
  public func buildTrack(forItems items: [TKTTPifierInputItem], startDate: Date, endDate: Date) -> Observable<[TKTTPifierOutputItem]> {
    let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
    let components = calendar.dateComponents([.day, .month, .year], from: startDate)
    return buildTrack(forItems: items, dateComponents: components)
  }
  
  public func buildTrack(forItems items: [TKTTPifierInputItem], dateComponents: DateComponents) -> Observable<[TKTTPifierOutputItem]>
  {
    guard let _ = items.first else {
      return Observable.just([])
    }
    
    // We need a stay to TTPify
    guard let _ = items.index(where: { $0.isStay })
    else {
      let outputs = items.flatMap { $0.asFakeOutput() }
      return Observable.just([TKTTPifierOutputItem.stayPlaceholder] + outputs + [TKTTPifierOutputItem.stayPlaceholder])
    }
    
    // We also need more than a single stay
    if items.count == 1 {
      let outputs = items.flatMap { $0.asFakeOutput() }
      return Observable.just(outputs)
    }
    
    // Got enough data to query server!
    let (list, set) = TKTTPifier.split(items)
    // return TKTTPifierFaker.fakeInsert(new, into: previous)
    return TKTTPifier.insert(set, into: list, dateComponents: dateComponents, modes: modes)
  }
  
  public static func split(_ items: [TKTTPifierInputItem]) -> (list: [TKTTPifierInputItem], set: [TKTTPifierInputItem])
  {
    guard let first = items.first else {
      preconditionFailure()
    }
    
    var list = items
      .filter { $0.fixedOrder != nil || $0.timesAreFixed }
      .sorted { return $0.beforeInList($1)
    }
    list.append(first)
    
    let set = items
      .filter { $0.fixedOrder == nil && !$0.timesAreFixed }
    
    return (list, set)
  }
  
  fileprivate static func insert(_ locations: [TKTTPifierInputItem], into: [TKTTPifierInputItem], dateComponents: DateComponents, modes: [String]? = nil) -> Observable<[TKTTPifierOutputItem]> {
    
    precondition(into.count >= 2, "Don't call this unless you have a start and end!")
    
    let merged = Array(into.prefix(into.count - 1)) + locations + Array(into.suffix(1))
    let placeholders = TKAgendaFaker.outputPlaceholders(merged)
    
    // 1. Create the problem (or the cached ID)
    return createProblem(locations, into: into, dateComponents: dateComponents, modes: modes)
      .flatMap { region, id  in
        // 2. Fetch the solution, both partial and full
        return fetchSolution(id, inputItems: into + locations, inRegion: region)
          .catchError { error in
            // 2a. If the solution has expired, clear the cache and create a new one
            if case TTPError.problemNotFoundOnServer = error {
              return clearCacheAndRetry(region, insert: locations, into: into, dateComponents: dateComponents, modes: modes)
            } else {
              throw error
            }
        }
      }
      .map { result -> [TKTTPifierOutputItem] in
        // 3. Return the results
        if let result = result {
          return result
        } else {
          // Can happen on 404
          return placeholders
        }
      }
      .catchError { error in
        // If user is offline, show placeholders with message in between
        if error.isNotConnectedError() {
          let title = NSLocalizedString("Connect to Internet to get trips", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Single line instruction if device is offline and user needs to reconnect to internet to calculate trips")
          let placeholders = TKAgendaFaker.outputPlaceholders(Array(merged), placeholderTitle: title)
          return Observable.just(placeholders)
        } else {
          throw error
        }
      }
      .startWith(placeholders)
      .throttle(0.1, scheduler: MainScheduler.instance) // To skip placeholder if we have cached result
      .observeOn(MainScheduler.instance)
  }
  
  fileprivate static func clearCacheAndRetry(_ region: SVKRegion, insert: [TKTTPifierInputItem], into: [TKTTPifierInputItem], dateComponents: DateComponents, modes: [String]? = nil) -> Observable<[TKTTPifierOutputItem]?> {

    // Clear the cache of problem ID
    let paras = createInput(insert, into: into, dateComponents: dateComponents, modes: modes, region: region)
    TKTTPifierCache.clear(forParas: paras)
    
    // Create problem and fetch solution again
    return createProblem(insert, into: into, dateComponents: dateComponents, region: region, modes: modes)
      .flatMap { region, id in
        return fetchSolution(id, inputItems: into + insert, inRegion: region)
    }
  }
  
  /**
   Creates the problem and sends it to the server for solving it.
   
   - parameter locations: New locations to add (unsorted)
   - parameter into: Sorted list of locations to add the new ones into. Typically starts and ends at a hotel.
   - returns: Observable sequence of the region where the problem starts and the id of the problem on the server.
   */
  fileprivate static func createProblem(_ insert: [TKTTPifierInputItem], into: [TKTTPifierInputItem], dateComponents: DateComponents, region: SVKRegion? = nil, modes: [String]? = nil) -> Observable<(SVKRegion, String)> {

    guard let first = into.first else {
      preconditionFailure("`into` needs at least one item")
    }
    
    // If a region was not supplied, fetch it, and recurse
    guard let region = region else {
      return SVKServer.shared.rx
        .requireRegion(first.start)
        .flatMap { region -> Observable<(SVKRegion, String)> in
          return self.createProblem(insert, into: into, dateComponents: dateComponents, region: region, modes: modes)
      }
    }
    
    let paras = createInput(insert, into: into, dateComponents: dateComponents, modes: modes, region: region)
    
    // Re-use the cached ID
    // If it doesn't exist anymore, we handle this in `fetchSolution`
    if let cachedId = TKTTPifierCache.problemId(forParas: paras) {
      return Observable.just((region, cachedId))
    }
    
    // If we don't have a cached ID, create a new problem on the server
    return SVKServer.shared.rx
      .hit(.POST, path: "ttp", parameters: paras, region: region)
      .retry(4)
      .map { code, response, _ -> (SVKRegion, String?) in
        if let json = response as? [String: Any],
           let id: String = try? json.value(for: "id") {
          TKTTPifierCache.save(problemId: id, forParas: paras)
          return (region, id)
        } else {
          assertionFailure("Unexpected result from server with code \(code): \(String(describing: response))")
          return (region, nil)
        }
      }
      .filter { $1 != nil }
      .map { ($0, $1!) }
  }
  
  
  /**
   Fetches the solution for the problem of the provided id from the server.
   
   - parameter id: ID of the solution, as returned by the server
   - parameter inputItems: Union of all the input items sent to the server
   - parameter region: Region where the problem starts
   - returns: Observable sequence with the output items or `nil` if the server couldn't calculate them
   */
  fileprivate static func fetchSolution(_ id: String, inputItems: [TKTTPifierInputItem], inRegion region: SVKRegion) -> Observable<[TKTTPifierOutputItem]?> {
    
    problemIDs.insert(id)

    let cachedJson = TKTTPifierCache.marshaledSolution(forId: id)
    let cachedItems: [TKTTPifierOutputItem]?
    if let json = cachedJson {
      cachedItems = createOutput(inputItems, json: json)
    } else {
      cachedItems = nil
    }
    
    let paras: [String: Any]
    if let cached = cachedJson, let hashCode: Int = try? cached.value(for: "hashCode") {
      paras = ["hashCode": hashCode]
    } else {
      paras = [:]
    }
    
    return SVKServer.shared.rx
      .hit(.GET, path: "ttp/\(id)/solution", parameters: paras, region: region) { code, response, _ in
        
        // Keep hitting if it's a 299 (solution still bein calculated)
        // or the input indicates that not all trips have been added yet
        if code == 299 {
          return 2.5;

        } else if let json = response as? [String: Any],
                  let hasAllTrips: Bool = try? json.value(for: "hasAllTrips") {
          return hasAllTrips ? nil : 2.5

        } else {
          return nil
        }
      }
      .filter { code, json, _ in
        if (code == 404 || code == 410) {
          throw TTPError.problemNotFoundOnServer
        }
        
        // Swallow 304 in particular (cached solution still up-to-date)
        return code == 200 && json != nil
      }
      .map { code, response, _ -> [TKTTPifierOutputItem]? in
        if let json = response as? [String: Any],
          let output = createOutput(inputItems, json: json) {
          TKTTPifierCache.save(marshaledSolution: json, forId: id)
          return output
        } else {
          return nil
        }
      }
      .catchError { error in
        if let cached = cachedItems, error.isNotConnectedError() {
          return Observable.just(cached)
        } else {
          throw error
        }
      }
      .startWith(cachedItems)
  }
  
  /**
   Creates the input as required by the `tpp/` endpoint.
   */
  fileprivate static func createInput(_ insert: [TKTTPifierInputItem], into: [TKTTPifierInputItem], dateComponents: DateComponents, modes: [String]? = nil, region: SVKRegion? = nil) -> [String: Any] {
    
    guard let year = dateComponents.year, let month = dateComponents.month, let day = dateComponents.day else {
      preconditionFailure("Provided bad date components")
    }
    
    let identifiers: [String]
    if let modes = modes {
      identifiers = modes
    } else if let region = region {
      var mutable = Set(region.modeIdentifiers)
      mutable.subtract([
        SVKTransportModeIdentifierCar,
        SVKTransportModeIdentifierBicycle,
        SVKTransportModeIdentifierMotorbike,
      ])
      identifiers = Array(mutable).sorted()
    } else {
      preconditionFailure("Need either modes or region")
    }
    
    return [
      "date": "\(year)-\(month)-\(day)",
      "modes": identifiers,
      "insertInto": createInput(into),
      "insert": createInput(insert)
    ]
  }
  
  /**
   Turn an array of `TKTTPifierInputItem` into the input for `tpp/` endpoint.
   */
  fileprivate static func createInput(_ items: [TKTTPifierInputItem])-> [ [String: Any] ] {
    return items.reduce([] as [[String: Any]]) { acc, input in
      if let next = input.asInput() {
        return acc + [next]
      } else {
        return acc
      }
    }
  }
  
  fileprivate static func createOutput(_ allInputs: [TKTTPifierInputItem], json: [String: Any]) -> [TKTTPifierOutputItem]?
  {
    guard let outputItems = json["items"] as? [[String: Any]] else { return nil }
    
    // Create look-up map of [identifier => event input]
    let eventInputs = allInputs
      .reduce([:] as [String: TKTTPifierEventInputType]) { acc, item in
        switch item {
        case .event(let input) where input.identifier != nil:
          var newAcc = acc
          newAcc[input.identifier!] = input
          return newAcc
          
        default:
          return acc
        }
      }
    
    // Parse output
    return outputItems.flatMap { item -> TKTTPifierOutputItem? in
      
      if let id: String = try? item.value(for: "locationId"),
         let input = eventInputs[id] {
        let eventOutput = TKTTPifierEventOutput(forInput: input)
        return .event(eventOutput)
      
      } else if let options: [TripOption] = try? item.value(for: "tripOptions") {
        return .tripOptions(options)
      
      } else {
        SGKLog.debug("TKTTPifier") { "Ignoring \(item)" }
        return nil
      }
    }
  }
  
  fileprivate struct TripOption: TKTTPifierTripOptionType, Unmarshaling {
    let usedModes: [ModeIdentifier]
    let segments: [TKTTPifierTripOptionSegmentType]
    let duration: TKTTPifierValue<TimeInterval>
    let price: TKTTPifierValue<PriceUnit>?
    let score: TKTTPifierValue<Double>
    
    init(object: MarshaledObject) throws {
      usedModes = try  object.value(for: "modes")
      duration  = try  object.value(for: "duration")
      price     = try? object.value(for: "price")
      score     = try  object.value(for: "score")
      
      let segments: [SegmentOverview] = try object.value(for: "segments")
      self.segments = segments
    }

  }
  
  fileprivate class SegmentOverview: NSObject, Unmarshaling {
    let modeInfo: ModeInfo
    let duration: Int
    let polyline: String?
    
    required init(object: MarshaledObject) throws {
      duration = try  object.value(for: "duration")
      polyline = try? object.value(for: "encodedPolyline")
      
      let dict: [String: Any] = try object.value(for: "modeInfo")
      let decoder = JSONDecoder()
      modeInfo = try decoder.decode(ModeInfo.self, withJSONObject: dict)
    }
  }
}

extension TKTTPifier.SegmentOverview: TKTTPifierTripOptionSegmentType {
  
  // MARK: STKTripSegmentDisplayable

  var tripSegmentModeColor: SGKColor? { return modeInfo.color }

  var tripSegmentModeImage: SGKImage? {
    return TKSegmentHelper.segmentImage(.listMainMode, modeInfo: modeInfo, modeIdentifier: nil, isRealTime: false)
  }
  
  var tripSegmentModeImageURL: URL? { return nil }
  
  var tripSegmentModeTitle: String? {
    if let description = modeInfo.descriptor, !description.isEmpty {
      return description
    } else {
      return nil
    }
  }
  
  var tripSegmentModeSubtitle: String? {
    if SVKTransportModes.modeIdentifierIsPublicTransport(modeInfo.identifier) {
      return nil
    } else {
      return Date.durationString(forMinutes: duration / 60)
    }
  }
  
  var tripSegmentModeInfoIconType: STKInfoIconType { return .none }
  var tripSegmentFixedDepartureTime: Date? { return nil }
  var tripSegmentTimeZone: TimeZone? { return nil }
  var tripSegmentTimesAreRealTime: Bool { return false }
  var tripSegmentIsWheelchairAccessible: Bool { return false }
  
  
  // MARK: STKDisplayableRoute

  var routeColor: SGKColor? {
    return tripSegmentModeColor
  }
  
  var routePath: [Any] {
    guard let polyline = self.polyline else { return [] }
    return CLLocation.decodePolyLine(polyline)
  }
  
  var routeDashPattern: [NSNumber]? {
    return nil
  }
  
  var showRoute: Bool {
    return true
  }
  
  var routeIsTravelled: Bool {
    return true
  }

}


extension TKTTPifierInputItem {
  public func beforeInList(_ other: TKTTPifierInputItem) -> Bool {
    let first = self
    let second = other
    
    let firstOrder = first.fixedOrder
    let secondOrder = second.fixedOrder

    // The order is this:
    // 1. Stays
    // 2. By order if both have an order
    // 3. By time if either has a fixed time
    // 4. Item with an order
    // 5. Arbitrary (by id)
    
    if first.isStay {
      // Stays are always first
      return true
    } else if second.isStay {
      return false
    
    } else if first.timesAreFixed && second.timesAreFixed {
      // If both have fixed times, use those
      return first.startTime!.compare(second.startTime! as Date) == .orderedAscending
      
    } else if let firstOrder = firstOrder,
      let secondOrder = secondOrder {
      // If both have an other, just use that
      return firstOrder < secondOrder
      
    } else if first.timesAreFixed {
      // If first has a fixed time, but second does not (though it might have a fixed order) then put fixed time event before
      return true

    } else if second.timesAreFixed {
      // ... and vice versa
      return false
    
    } else if let _ = firstOrder {
      return true
    
    } else if let _ = secondOrder {
      return false
    
    } else {
      return true
    }
    
  }
  
  /**
   Turn a `TKTTPifierInputItem` into the input for `tpp/` endpoint.
   */
  fileprivate func asInput() -> [String: Any]? {
    switch self {
    case .event(let input):
      guard let id = input.identifier else {
        assertionFailure("Input event has no identifier: \(input)")
        return nil
      }
      return [
        "id": id,
        "lat": input.coordinate.latitude,
        "lng": input.coordinate.longitude,
      ]
    
    case .trip:
      return nil
    }
  }
}
