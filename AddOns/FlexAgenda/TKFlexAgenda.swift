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
    guard let first = items.first else {
      return Observable.just([])
    }
    
    // TODO: Decide based on data. Typically new events should go into `new` unless at least two elements have times, then we do something new
    let new = items[1 ..< items.count]
    let previous = [first, first]
    
//    return TKFlexAgendaFaker.fakeInsert(new, into: previous)
    return TKTTPifier.insert(Array(new), into: previous)
  }
}
