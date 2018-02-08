//
//  TKAgendaParserHelper.swift
//  TripKit
//
//  Created by Adrian Schoenig on 2/03/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public class TKAgendaParserHelper: NSObject {
  public static func vehiclesPayload(forVehicles vehicles: [STKVehicular]?) -> [ [String: Any] ]? {
    guard let vehicles = vehicles else { return nil }
    
    return vehicles.map(STKVehicularHelper.skedGoFullDictionary)
  }
}
