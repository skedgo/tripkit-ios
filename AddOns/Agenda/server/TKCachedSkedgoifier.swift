//
//  TKCachedSkedgoifier.swift
//  RioGo
//
//  Created by Adrian Schoenig on 7/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

struct TKCachedSkedgoifier: TKAgendaBuilderType {

  func buildTrack(forItems items: [TKAgendaInputItem], startDate: NSDate, endDate: NSDate, privateVehicles: [STKVehicular], tripPatterns: [ [String: AnyObject] ]) -> Observable<[TKAgendaOutputItem]> {
    let skedgoifier = TKSkedgoifier()
    return skedgoifier.buildTrack(forItems: items, startDate: startDate, endDate: endDate, privateVehicles: privateVehicles, tripPatterns: tripPatterns)
  }
}