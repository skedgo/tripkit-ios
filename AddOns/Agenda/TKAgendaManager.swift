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
  func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate, privateVehicles: [STKVehicular], tripPatterns: [ [String: AnyObject] ]) -> Observable<[TKAgendaOutputItem]>
}

extension TKAgendaBuilderType {
  func buildTrack(forItems items: [TKAgendaInputItem], dateComponents: NSDateComponents) -> Observable<[TKAgendaOutputItem]> {
    let startDate = dateComponents.earliestDate()
    let endDate = dateComponents.latestDate()
    return buildTrack(forItems: items, startDate: startDate, endDate: endDate, privateVehicles: [], tripPatterns: [])
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
      print("Ignore subsequent call to `initialize`.")
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
  
  private var agendas = [NSDateComponents : TKAgendaType]()
  
  public func agenda(dateComponents: NSDateComponents) -> TKAgendaType {
    if let agenda = agendas[dateComponents] {
      return agenda
    }
    
    // FIXME: For now, we just use the items of the first data source
    guard let rawItems = dataSources.first?.items(dateComponents) else {
      fatalError("Data sources shalt not be empty")
    }
    
    let trackItems = rawItems.flatMap { data in
      // If that throws an error, we shouldn't propagate that up!
      self.builder.buildTrack(forItems: data, dateComponents: dateComponents).asDriver(onErrorJustReturn: [])
    }
    
    let agenda = TKSimpleAgenda(items: trackItems, dateComponents: dateComponents)
    agendas[dateComponents] = agenda
    return agenda
  }
}

private struct TKSimpleAgenda: TKAgendaType {
  let startDate: NSDate
  let endDate: NSDate
  let items: Observable<[TKAgendaOutputItem]>
  
  init(items: Observable<[TKAgendaOutputItem]>, dateComponents: NSDateComponents) {
    self.items = items
    self.startDate = dateComponents.earliestDate()
    self.endDate = dateComponents.latestDate()
  }
}

