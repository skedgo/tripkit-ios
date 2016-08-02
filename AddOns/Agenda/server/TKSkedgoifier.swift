//
//  TKSkedgoifier.swift
//  RioGo
//
//  Created by Adrian Schoenig on 7/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

import SGCoreKit

extension TKSkedgoifier {
  /**
   - warning: While this basically implements the `TKAgendaBuilderType`, you can't use it multi-threaded. You're encouraged to use `TKCachedSkedgoifier` instead which is multi-threading safe (and does caching, too).
   */
  public func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate, privateVehicles: [STKVehicular], tripPatterns: [ [String: AnyObject] ]) -> Observable<[TKAgendaOutputItem]> {
    
    return SVKServer.sharedInstance()
      .rx_requireRegion(MKCoordinateRegion.forItems(items))
      .flatMap { region in
        return self.fetchTrips(forItems: items, startDate: startDate, endDate: endDate, inRegion: region, privateVehicles: privateVehicles, tripPatterns: tripPatterns)
      }
  }
  
  private func fetchTrips(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate, inRegion region: SVKRegion, privateVehicles: [STKVehicular], tripPatterns: [ [String: AnyObject] ]) -> Observable<[TKAgendaOutputItem]> {
    
    if items.isEmpty {
      return Observable.just([])
    }
    
    let inputs = items.reduce([] as [AnyObject]) { inputs, item in
      switch item {
      case let .Event(eventInput):
        return inputs + [eventInput]
      case let .Trip(tripInput):
        return inputs + [tripInput]
      }
    }
    
    return Observable.create { subscriber in
      
      subscriber.onNext(TKAgendaFaker.outputPlaceholders(items))
      
      self.fetchTripsForItems(inputs, startDate: startDate, endDate: endDate, inRegion: region, withPrivateVehicles: privateVehicles, withTripPatterns: tripPatterns) { results, error in
        
        guard error == nil else {
          subscriber.onError(error!)
          return
        }
        
        guard let results = results else {
          // Typically when there's just a single item
          if let firstInput = items.first,
             case let .Event(eventInput) = firstInput {
            let eventOutput = TKSkedgoifierEventOutput(forInput: eventInput, effectiveStart: startDate, effectiveEnd: endDate, isContinuation: false)
            let output = TKAgendaOutputItem.Event(eventOutput)
            subscriber.onNext([output])
            subscriber.onCompleted()
            return
          } else {
            fatalError("`items.isEmpty` above should have triggered")
          }
        }
        
        let outputs = results.reduce([] as [TKAgendaOutputItem]) { outputs, result in
          if let eventOutput = result as? TKAgendaEventOutput {
            return outputs + [ .Event(eventOutput) ]
          } else if let tripOutput = result as? TKAgendaTripOutput {
            return outputs + [ .Trip(tripOutput) ]
          } else {
            fatalError("Unexpected item from skedgoifier: \(result)")
          }
        }
        
        subscriber.onNext(outputs)
        subscriber.onCompleted()
      }
      
      return NopDisposable.instance
    }
    
  }
}

