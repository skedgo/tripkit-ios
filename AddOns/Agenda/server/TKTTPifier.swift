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

enum TKTTPifier {
  enum Error : ErrorType {
    case creatingProblemFailedOnServer
    case fetchingSolutionFailedOnServer
  }
  
  static func insert(locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {
    
    // TODO: Add stay at end, too
    // TODO: Don't fetch if there's just one or the first is the same as the last
    
    let placeholders = TKAgendaFaker.outputPlaceholders(into)
    
    let paras = createInput(locations, into: into)
    // TODO: Create a hash code of the paras, check if we have an ID in the cache already, then hit GET

    let region: SVKRegion? = nil // TODO: Fix
    
    return SVKServer.sharedInstance()
      .rx_hit(.POST, path: "ttp", parameters: paras, region: region)
      .retry(4)
      .flatMap { code, json -> Observable<(Int, JSON?)>  in
        guard let id = json?["id"].string else {
          // TODO: Log 400 bad input errors
          // TODO: Treat this as a bigger error
          return Observable.error(Error.creatingProblemFailedOnServer)
        }
        
        return SVKServer.sharedInstance()
          .rx_hit(.GET, path: "ttp/\(id)/solution", region: region)
      }
      .map { code, json -> [TKAgendaOutputItem] in
        // TODO: Deal with 299 (solution not available yet)
        // TODO: Deal with 304 (solution still up-to-date)
        
        if let json = json,
           let output = createOutput(into + locations, json: json) {
          return output
        } else {
          return placeholders // TODO: Fix this?
        }
      }
      .startWith(placeholders)
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
            let mins = json["duration"]["average"].double,
            let score = json["score"]["average"].float
        else {
          return nil
      }
      
      let duration = NSTimeInterval(mins * 60)
      let price = json["price"]["average"].float
      return TripOption(modes: modes, duration: duration, price: price, score: score)
    }
    
    return options.isEmpty ? nil : []
  }
  
  private struct TripOption: TKAgendaTripOptionType {
    let modes: [ModeIdentifier]
    let duration: NSTimeInterval
    let price: PriceUnit?
    let score: Float
  }
}

extension TKAgendaInputItem {
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
