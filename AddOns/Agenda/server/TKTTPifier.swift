//
//  TKTTPifier.swift
//  RioGo
//
//  Created by Adrian Schoenig on 16/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift
import SwiftyJSON

public struct TKTTPifier : TKAgendaBuilderType {
  enum Error : ErrorType {
    case creatingProblemFailedOnServer
    case fetchingSolutionFailedOnServer
    case problemNotFoundOnServer
  }
  
  public init() {
    
  }
  
  public func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate) -> Observable<[TKAgendaOutputItem]> {
    guard let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian) else {
      preconditionFailure()
    }
    let components = calendar.components(
      [NSCalendarUnit.Day, NSCalendarUnit.Month, NSCalendarUnit.Year],
      fromDate: startDate
    )
    return buildTrack(forItems: items, dateComponents: components)
  }
  
  public func buildTrack(forItems items: [TKAgendaInputItem], dateComponents: NSDateComponents) -> Observable<[TKAgendaOutputItem]>
  {
    guard let _ = items.first else {
      return Observable.just([])
    }
    
    // We need a stay to TTPify
    guard let firstStay = items.indexOf({ $0.isStay })
    else {
      let outputs = items.flatMap { $0.asFakeOutput() }
      return Observable.just([TKAgendaOutputItem.StayPlaceholder] + outputs + [TKAgendaOutputItem.StayPlaceholder])
    }
    
    // We also need more than a single stay
    if items.count == 1 {
      let outputs = items.flatMap { $0.asFakeOutput() }
      return Observable.just(outputs)
    }
    
    // Got enough data to query server!
    let (list, set) = TKTTPifier.split(items)
    // return TKTTPifierFaker.fakeInsert(new, into: previous)
    return TKTTPifier.insert(set, into: list, dateComponents: dateComponents)
  }
  
  public static func split(items: [TKAgendaInputItem]) -> (list: [TKAgendaInputItem], set: [TKAgendaInputItem])
  {
    guard let first = items.first else {
      preconditionFailure()
    }
    
    var list = items
      .filter { $0.fixedOrder != nil || $0.timesAreFixed }
      .sort { return $0.beforeInList($1)
    }
    list.append(first)
    
    let set = items
      .filter { $0.fixedOrder == nil && !$0.timesAreFixed }
    
    return (list, set)
  }
  
  private static func insert(locations: [TKAgendaInputItem], into: [TKAgendaInputItem], dateComponents: NSDateComponents) -> Observable<[TKAgendaOutputItem]> {
    
    precondition(into.count >= 2, "Don't call this unless you have a start and end!")
    
    let merged = into.prefix(into.count - 1) + locations + into.suffix(1)
    
    let placeholders = TKAgendaFaker.outputPlaceholders(Array(merged))
    
    // 1. Create the problem (or the cached ID)
    return rx_createProblem(locations, into: into, dateComponents: dateComponents)
      .flatMap { region, id  in
        // 2. Fetch the solution, both partial and full
        return rx_fetchSolution(id, inputItems: into + locations, inRegion: region)
          .catchError { error in
            // 2a. If the solution has expired, clear the cache and create a new one
            if case let Error.problemNotFoundOnServer = error {
              return rx_clearCacheAndRetry(region, insert: locations, into: into, dateComponents: dateComponents)
            } else {
              throw error
            }
        }
      }
      .map { result -> [TKAgendaOutputItem] in
        // 3. Return the results
        if let result = result {
          return result
        } else {
          return placeholders // TDOO: Fix this?
        }
      }
      .startWith(placeholders)
      .throttle(0.1, scheduler: MainScheduler.instance) // To skip placeholder if we have cached result
      .observeOn(MainScheduler.instance)
  }
  
  private static func rx_clearCacheAndRetry(region: SVKRegion, insert: [TKAgendaInputItem], into: [TKAgendaInputItem], dateComponents: NSDateComponents) -> Observable<[TKAgendaOutputItem]?> {

    // Clear the cache of problem ID
    let paras = createInput(region, insert: insert, into: into, dateComponents: dateComponents)
    TKTTPifierCache.clear(forParas: paras)
    
    // Create problem and fetch solution again
    return rx_createProblem(insert, into: into, dateComponents: dateComponents, region: region)
      .flatMap { region, id in
        return rx_fetchSolution(id, inputItems: into + insert, inRegion: region)
    }
  }
  
  /**
   Creates the problem and sends it to the server for solving it.
   
   - parameter locations: New locations to add (unsorted)
   - parameter into: Sorted list of locations to add the new ones into. Typically starts and ends at a hotel.
   - returns: Observable sequence of the region where the problem starts and the id of the problem on the server.
   */
  private static func rx_createProblem(insert: [TKAgendaInputItem], into: [TKAgendaInputItem], dateComponents: NSDateComponents, region: SVKRegion? = nil) -> Observable<(SVKRegion, String)> {

    guard let first = into.first else {
      preconditionFailure("`into` needs at least one item")
    }
    
    // If a region was not supplied, fetch it, and recurse
    guard let region = region else {
      return SVKServer.sharedInstance()
        .rx_requireRegion(first.start)
        .flatMap { region -> Observable<(SVKRegion, String)> in
          return self.rx_createProblem(insert, into: into, dateComponents: dateComponents, region: region)
      }
    }
    
    let paras = createInput(region, insert: insert, into: into, dateComponents: dateComponents)
    
    // Re-use the cached ID
    // If it doesn't exist anymore, we handle this in `rx_fetchSolution`
    if let cachedId = TKTTPifierCache.problemId(forParas: paras) {
      return Observable.just((region, cachedId))
    }
    
    // If we don't have a cached ID, create a new problem on the server
    return SVKServer.sharedInstance()
      .rx_hit(.POST, path: "ttp", parameters: paras, region: region)
      .retry(4)
      .map { code, json -> (SVKRegion, String?) in
        if let id = json?["id"].string {
          TKTTPifierCache.save(problemId: id, forParas: paras)
          return (region, id)
        } else {
          assertionFailure("Unexpected result from server with code \(code): \(json)")
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
  private static func rx_fetchSolution(id: String, inputItems: [TKAgendaInputItem], inRegion region: SVKRegion) -> Observable<[TKAgendaOutputItem]?> {
    
    let cachedJson = TKTTPifierCache.solutionJson(forId: id)
    let cachedItems: [TKAgendaOutputItem]?
    if let json = cachedJson {
      cachedItems = createOutput(inputItems, json: json)
    } else {
      cachedItems = nil
    }
    
    let paras: [String: AnyObject]
    if let json = cachedJson,
       let hashCode = json["hashCode"].int {
      paras = ["hashCode": hashCode]
    } else {
      paras = [:]
    }
    
    return SVKServer.sharedInstance()
      .rx_hit(.GET, path: "ttp/\(id)/solution", parameters: paras, region: region) { code, json in
        
        // Keep hitting if it's a 299 (solution still bein calculated)
        // or the input indicates that not all trips have been added yet
        if code == 299 {
          return true;

        } else if let hasAllTrips = json?["hasAllTrips"].bool {
          return !hasAllTrips

        } else {
          return false
        }
      }
      .filter { code, json in
        if (code == 404 || code == 410) {
          throw Error.problemNotFoundOnServer
        }
        
        // Swallow 304 in particular (cached solution still up-to-date)
        return code == 200 && json != nil
      }
      .map { code, json -> [TKAgendaOutputItem]? in
        if let json = json,
          let output = createOutput(inputItems, json: json) {
          TKTTPifierCache.save(solutionJson: json, forId: id)
          return output
        } else {
          return nil
        }
      }.startWith(cachedItems)
  }
  
  /**
   Creates the input as required by the `tpp/` endpoint.
   */
  private static func createInput(region: SVKRegion, insert: [TKAgendaInputItem], into: [TKAgendaInputItem], dateComponents: NSDateComponents) -> [String: AnyObject] {
    let publicModes = Set(region.modeIdentifiers).subtract([
      SVKTransportModeIdentifierCar,
      SVKTransportModeIdentifierBicycle,
      SVKTransportModeIdentifierMotorbike,
    ])
    
    return [
      "date": "\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day)",
      "modes": Array(publicModes).sort(),
      "insertInto": createInput(into),
      "insert": createInput(insert)
    ]
  }
  
  /**
   Turn an array of `TKAgendaInputItem` into the input for `tpp/` endpoint.
   */
  private static func createInput(items: [TKAgendaInputItem])-> [ [String: AnyObject] ] {
    return items.reduce([] as [[String: AnyObject]]) { acc, input in
      if let next = input.asInput() {
        return acc + [next]
      } else {
        return acc
      }
    }
  }
  
  private static func createOutput(allInputs: [TKAgendaInputItem], json: JSON) -> [TKAgendaOutputItem]?
  {
    guard let outputItems = json["items"].array else { return nil }
    
    // Create look-up map of [identifier => event input]
    let eventInputs = allInputs
      .reduce([:] as [String: TKAgendaEventInputType]) { acc, item in
        switch item {
        case .Event(let input) where input.identifier != nil:
          var newAcc = acc
          newAcc[input.identifier!] = input
          return newAcc
          
        default:
          return acc
        }
      }
    
    // Parse output
    return outputItems.flatMap { item -> TKAgendaOutputItem? in
      
      if let id = item["locationId"].string,
         let input = eventInputs[id] {
        let eventOutput = TKAgendaEventOutput(forInput: input)
        return .Event(eventOutput)
      
      } else if let tripOptionsJSON = item["tripOptions"].array,
                let tripOptions = parse(tripOptionsJSON) {
        return .TripOptions(tripOptions)
      
      } else {
        SGKLog.debug("TKTTPifier") { "Ignoring \(item)" }
        return nil
      }
    }
  }
  
  private static func parse(array: [JSON]) -> [TKAgendaTripOptionType]? {
    let options = array.flatMap { json -> TKAgendaTripOptionType? in
      
      guard let modes = json["modes"].arrayObject as? [String],
            let segments = json["segments"].array,
            let seconds = json["duration"]["average"].double,
            let score = json["score"]["average"].float
        else {
          return nil
      }
      
      return TripOption(
        usedModes: modes,
        segments: segments.flatMap { SegmentOverview(json: $0) },
        duration: NSTimeInterval(seconds),
        price: json["price"]["average"].float,
        score: score
      )
    }
    
    return options.isEmpty ? nil : options
  }
  
  private struct TripOption: TKAgendaTripOptionType {
    let usedModes: [ModeIdentifier]
    let segments: [STKTripSegmentDisplayable]
    let duration: NSTimeInterval
    let price: PriceUnit?
    let score: Float
  }
  
  private class SegmentOverview: NSObject, STKTripSegmentDisplayable {
    private let modeInfo: ModeInfo
    private let duration: Int
    private let polyline: String?
    
    @objc private var tripSegmentModeImage: UIImage? {
      return TKSegmentHelper.segmentImage(.ListMainMode, modeInfo: modeInfo, modeIdentifier: nil, isRealTime: false)
    }
    
    @objc private func tripSegmentModeColor() -> UIColor? {
      return modeInfo.color
    }
    
    @objc private func tripSegmentModeTitle() -> String? {
      if let description = modeInfo.descriptor where !description.isEmpty {
        return description
      } else {
        return nil
      }
    }
    
    @objc private func tripSegmentModeSubtitle() -> String? {
      if SVKTransportModes.modeIdentifierIsPublicTransport(modeInfo.identifier) {
        return nil
      } else {
        return NSDate.durationString(forMinutes: duration / 60)
      }
    }
    
    init(modeInfo: ModeInfo, duration: Int, polyline: String?) {
      self.modeInfo = modeInfo
      self.duration = duration
      self.polyline = polyline
      super.init()
    }
    
    private convenience init?(json: JSON) {
      guard let duration = json["duration"].int,
            let modeDict = json["modeInfo"].dictionaryObject,
            let modeInfo = ModeInfo(forDictionary: modeDict)
        else {
          return nil
      }
      
      let polyline = json["encodedPolyline"].stringValue
      self.init(
        modeInfo: modeInfo,
        duration: duration,
        polyline: polyline.isEmpty ? nil : polyline
      )
    }
  }
}

extension TKAgendaInputItem {
  public func beforeInList(other: TKAgendaInputItem) -> Bool {
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
      return first.startTime!.compare(second.startTime!) == .OrderedAscending
      
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
   Turn a `TKAgendaInputItem` into the input for `tpp/` endpoint.
   */
  private func asInput() -> [String: AnyObject]? {
    switch self {
    case .Event(let input):
      guard let id = input.identifier else { return nil }
      return [
        "id": id,
        "lat": input.coordinate.latitude,
        "lng": input.coordinate.longitude,
      ]
    
    case .Trip:
      return nil
    }
  }
}
