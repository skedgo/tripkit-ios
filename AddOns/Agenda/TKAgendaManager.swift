
//
//  RGAgendaLogic.swift
//  RioGo
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
  func items(dateComponents: NSDateComponents) -> Observable<[TKAgendaInputItem]>
}

public protocol TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate) -> Observable<[TKAgendaOutputItem]>
}

extension TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], dateComponents: NSDateComponents) -> Observable<[TKAgendaOutputItem]> {
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
  
  public class func initialize(builder: TKAgendaBuilderType, dataSources: [TKAgendaDataSource]) {
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
  
  public func agenda(dateComponents: NSDateComponents) -> TKAgendaType {
    let key = "\(dateComponents.year)-\(dateComponents.month)-\(dateComponents.day)"
    if let agenda = agendas[key] {
      return agenda
    }
    
    // FIXME: For now, we just use the items of the first data source
    guard let rawItems = dataSources.first?.items(dateComponents) else {
      fatalError("Data sources shalt not be empty")
    }
    
    let lastError = Variable<ErrorType?>(nil)
    
    let trackItems = rawItems.flatMap { data in
      // If that throws an error, we shouldn't propagate that up!
      return self.builder.buildTrack(forItems: data, dateComponents: dateComponents).asDriver {
        error in
        lastError.value = error
        return Observable.empty().asDriver(onErrorJustReturn: [])
      }
      }.distinctUntilChanged { previous, new in
        return self.outputItemsEqual(previous, new: new)
      }
    
    let agenda = TKSimpleAgenda(items: trackItems, lastError: lastError.asObservable(), dateComponents: dateComponents)
    agendas[key] = agenda
    return agenda
  }
  
  private func outputItemsEqual(previous: [TKAgendaOutputItem], new: [TKAgendaOutputItem]) -> Bool {
    if previous.count != new.count {
      return false
    }
    
    for pair in zip(previous, new) {
      switch pair {
      case (.Trip, .Trip), (.TripPlaceholder, .TripPlaceholder):
        // Treat same base type as the same
        // TODO: FIX!
        break
        
      case (.Event(let prevEvent), .Event(let newEvent)) where prevEvent.equalsForAgenda(newEvent):
        break
        
      case (.TripOptions(let prevItems), .TripOptions(let newItems)) where prevItems.count == newItems.count:
        // Treat same count as the same
        break
      default:
        return false
      }
    }
    
    return true
  }
}

private struct TKSimpleAgenda: TKAgendaType {
  let startDate: NSDate
  let endDate: NSDate
  let items: Observable<[TKAgendaOutputItem]>
  let lastError: Observable<ErrorType?>
  
  init(items: Observable<[TKAgendaOutputItem]>, lastError: Observable<ErrorType?>, dateComponents: NSDateComponents) {
    self.items = items
    self.lastError = lastError
    self.startDate = dateComponents.earliestDate()
    self.endDate = dateComponents.latestDate()
  }
}

