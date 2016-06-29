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
  }
  
  public init() {
    
  }
  
  public func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate) -> Observable<[TKAgendaOutputItem]>
  {
    // We need a stay to TTPify
    guard let firstStay = items.indexOf({ $0.isStay })
    else {
      let outputs = items.flatMap { $0.asFakeOutput() }
      return Observable.just(outputs)
    }
    
    // We also need more than a single stay
    if items.count == 1 {
      let outputs = items.flatMap { $0.asFakeOutput() }
      return Observable.just(outputs)
    }
    
    // Got enough data to query server!
    let (list, set) = TKTTPifier.split(items)
    // return TKTTPifierFaker.fakeInsert(new, into: previous)
    return TKTTPifier.insert(set, into: list)
  }
  
  public static func split(items: [TKAgendaInputItem]) -> (list: [TKAgendaInputItem], set: [TKAgendaInputItem])
  {
    guard let first = items.first else {
      preconditionFailure()
    }
    
    // TODO: Handle when at least two elements have times
    
    // We start with the list being all the ordered elements...
    var list = items
      .filter { $0.fixedOrder != nil || $0.timesAreFixed }
      .sort { return $0.beforeInList($1)
    }
    list.append(first)
    
    let set = items
      .filter { $0.fixedOrder == nil && !$0.timesAreFixed }
    
    return (list, set)
  }
  
  private static func insert(locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {
    
    precondition(into.count >= 2, "Don't call this unless you have a start and end!")
    
    let merged = into.prefix(into.count - 1) + locations + into.suffix(1)
    
    let placeholders = TKAgendaFaker.outputPlaceholders(Array(merged))
    
    return rx_createProblem(locations, into: into)
      .flatMap { region, id  in
        return fetchSolution(id, inputItems: into + locations, inRegion: region)
      }
      .map { result -> [TKAgendaOutputItem] in
        if let result = result {
          return result
        } else {
          return placeholders // TDOO: Fix this?
        }
      }
      .startWith(placeholders)
      .throttle(0.5, scheduler: MainScheduler.instance) // To skip placeholder if we have cached result
      .observeOn(MainScheduler.instance)
  }
  
  /**
   Creates the problem and sends it to the server for solving it.
   
   - parameter locations: New locations to add (unsorted)
   - parameter into: Sorted list of locations to add the new ones into. Typically starts and ends at a hotel.
   - returns: Observable sequence of the region where the problem starts and the id of the problem on the server.
   */
  private static func rx_createProblem(locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> Observable<(SVKRegion, String)> {
    
    guard let first = into.first else {
      preconditionFailure("`into` needs at least one item")
    }
    
    let server = SVKServer.sharedInstance()
    let paras = createInput(locations, into: into)
    
    return server
      .rx_requireRegion(first.start)
      .flatMap { region -> Observable<(SVKRegion, String)> in
        
        if let cachedId = TKTTPifierCache.problemId(forParas: paras) {
          return Observable.just((region, cachedId))
        }
        
        return server
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
  }
  
  
  /**
   Fetches the solution for the problem of the provided id from the server.
   
   - parameter id: ID of the solution, as returned by the server
   - parameter inputItems: Union of all the input items sent to the server
   - parameter region: Region where the problem starts
   - returns: Observable sequence with the output items or `nil` if the server couldn't calculate them
   */
  private static func fetchSolution(id: String, inputItems: [TKAgendaInputItem], inRegion region: SVKRegion) -> Observable<[TKAgendaOutputItem]?> {
    
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
  private static func createInput(locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> [String: AnyObject] {
    
    return [
      "date": "2016-06-30",
      "modes": ["pt_pub", "ps_tax"],
      "insertInto": createInput(into),
      "insert": createInput(locations)
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
            let seconds = json["duration"]["average"].double,
            let score = json["score"]["average"].float
        else {
          return nil
      }
      
      let duration = NSTimeInterval(seconds)
      let price = json["price"]["average"].float
      return TripOption(modes: modes, duration: duration, price: price, score: score)
    }
    
    return options.isEmpty ? nil : options
  }
  
  private struct TripOption: TKAgendaTripOptionType {
    let modes: [ModeIdentifier]
    let duration: NSTimeInterval
    let price: PriceUnit?
    let score: Float
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
