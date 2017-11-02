
//
//  RGAgendaLogic.swift
//  TripKit
//
//  Created by Adrian Schoenig on 25/02/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

/**
 A data source provides classes or structs conforming to the `TKAgendaInputType` protocol for
 specified date components. The date components will typically be for a specific date, but
 without timezone information. Treat this as "What has the user planned for this calendar
 date", regardless of the time zone the event is in.
 */
public protocol TKAgendaDataSource {
  func items(_ dateComponents: DateComponents) -> Observable<[TKAgendaInputItem]>
}

public protocol TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], startDate: Date, endDate: Date) -> Observable<[TKAgendaOutputItem]>
}

extension TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], dateComponents: DateComponents) -> Observable<[TKAgendaOutputItem]> {
    let startDate = dateComponents.earliestDate()
    let endDate = dateComponents.latestDate()
    return buildTrack(forItems: items, startDate: startDate, endDate: endDate)
  }
}

/**
 Main singleton class which acts as the gateway to getting an agenda for a day, updating it, calculating it using server calls, and everything else.
 
 - Note: Make sure to initialise the singleton with the data sources it
            should use before you use it.
 */
public class TKAgendaManager {
  private static var _singleton: TKAgendaManager?
  public class var singleton: TKAgendaManager {
    if let singleton = _singleton {
      return singleton
    } else {
      fatalError("Call `initialize` first!")
    }
  }
  
  public class func initialize(_ builder: TKAgendaBuilderType, dataSources: [TKAgendaDataSource]) {
    guard nil == _singleton else {
      assertionFailure("Ignore subsequent call to `initialize`.")
      return
    }
    _singleton = TKAgendaManager(builder: builder, dataSources: dataSources)
  }

  private init(builder: TKAgendaBuilderType, dataSources: [TKAgendaDataSource]) {
    self.dataSources = dataSources
    self.builder = builder
  }
  
  private let dataSources: [TKAgendaDataSource]
  private let builder: TKAgendaBuilderType
  
  private var agendas = [String : TKAgendaType]()
  
  public func agenda(_ dateComponents: DateComponents) -> TKAgendaType {
    let key = "\(dateComponents.year ?? 0000)-\(dateComponents.month ?? 00)-\(dateComponents.day ?? 00)"
    if let agenda = agendas[key] {
      return agenda
    }
    
    // TODO: For now, we just use the items of the first data source. Ideally we'd merge them.
    guard let inputItems = dataSources.first?.items(dateComponents) else {
      fatalError("Data sources shalt not be empty")
    }
    
    let agenda = TKSimpleAgenda(dateComponents: dateComponents, inputs: inputItems, builder: builder)
    agenda.engage()
    agendas[key] = agenda
    return agenda
  }
}

private struct TKSimpleAgenda: TKAgendaType {
  let dateComponents: DateComponents
  let inputs: Observable<[TKAgendaInputItem]>
  let builder: TKAgendaBuilderType

  let triggerRebuild = Variable(false)
  let outputs = Variable<[TKAgendaOutputItem]?>(nil)
  let outputError = Variable<Error?>(nil)
  let generationCount = Variable<Int>(0)
  
  var startDate: Date {
    return dateComponents.earliestDate()
  }
  
  var endDate: Date {
    return dateComponents.latestDate()
  }

  var inputItems: Observable<[TKAgendaInputItem]> {
    return inputs.asObservable()
  }

  var outputItems: Observable<[TKAgendaOutputItem]?> {
    return outputs.asObservable()
  }
  
  var lastError: Observable<Error?> {
    return outputError.asObservable()
  }
  
  fileprivate func engage() {
    Observable.combineLatest(inputs, triggerRebuild.asObservable()) { items, trigger in
        return ( items, trigger )
      }
        // Give CoreData a bit of time to catch up after triggering rebuild
      .throttle(0.5, scheduler: MainScheduler.instance)
      .filter { _, trigger in
        // Ignore input changes if we aren't allowed to trigger a rebuild
        return trigger
      }
      .map { items, _ -> ([TKAgendaInputItem], Int)  in
        // Don't retrigger again
        self.triggerRebuild.value = false
        
        // Keep generation count, to avoid returning outdated results
        let newGeneration = self.generationCount.value + 1
        self.generationCount.value = newGeneration
        return (items, newGeneration)
      }
      .flatMap { inputs, generation in
        // Inputs have changed, so now we trigger a rebuild
        // If that throws an error, we shouldn't propagate that up!
        // This is also where we ignore outdated generations.
        return self.builder
          .buildTrack(forItems: inputs, dateComponents: self.dateComponents)
          .filter { _ in
            self.generationCount.value == generation
          }
          .map { outputs in
            self.outputError.value = nil
            return outputs
          }
          .asDriver { error in
            self.outputError.value = error
            return Observable.empty().asDriver(onErrorJustReturn: [])
        }
      }
      .bind(to: outputs)
  }
}

