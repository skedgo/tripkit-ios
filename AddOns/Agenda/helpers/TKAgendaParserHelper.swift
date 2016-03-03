//
//  TKAgendaParserHelper.swift
//  TripGo
//
//  Created by Adrian Schoenig on 2/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

class TKAgendaParserHelper: NSObject {
  static func vehiclesPayload(forVehicles vehicles: [STKVehicular]?) -> [ [String: AnyObject] ]? {
    guard let vehicles = vehicles else { return nil }
    
    return vehicles.map(STKVehicularHelper.skedGoFullDictionaryForVehicle)
  }
}