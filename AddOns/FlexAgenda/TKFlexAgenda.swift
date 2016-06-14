//
//  TKFlexAgenda.swift
//  RioGo
//
//  Created by Adrian Schoenig on 14/06/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import CoreLocation
import RxSwift

public struct TKFlexAgenda : TKAgendaBuilderType {

  public func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate) -> Observable<[TKAgendaOutputItem]>
  {
    return TKFlexAgendaFaker.fakeInsert(items, into: items)
  }
  
  // MARK: TODO: Deal will all those cases properly (probably just do it internally depending on HOW the data has changed)
  
  public static func suggestOrder(locations: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {
    return insert(locations, into: [])
  }

  public static func insert(locations: [TKAgendaInputItem], into: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {
    return TKFlexAgendaFaker.fakeInsert(locations, into: into)
  }

  public static func udpateTrips(visits: [TKAgendaInputItem]) -> Observable<[TKAgendaOutputItem]> {
    return insert([], into: visits)
  }

}
