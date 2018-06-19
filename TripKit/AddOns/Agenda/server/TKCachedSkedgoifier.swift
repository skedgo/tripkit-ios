//
//  TKCachedSkedgoifier.swift
//  TripKit
//
//  Created by Adrian Schoenig on 7/03/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

import RxSwift



struct TKCachedSkedgoifier: TKAgendaBuilderType {

  let privateVehicles: [STKVehicular]
  let tripPatterns: [ [String: AnyObject] ]
  
  init(privateVehicles: [STKVehicular] = [], tripPatterns: [ [String: AnyObject] ] = []) {
    self.privateVehicles = privateVehicles
    self.tripPatterns = tripPatterns
  }

  
  func buildTrack(forItems items: [TKAgendaInputItem], startDate: Date, endDate: Date) -> Observable<[TKAgendaOutputItem]> {
    let skedgoifier = TKSkedgoifier()
    return skedgoifier.buildTrack(forItems: items, startDate: startDate, endDate: endDate, privateVehicles: privateVehicles, tripPatterns: tripPatterns)
  }
}
