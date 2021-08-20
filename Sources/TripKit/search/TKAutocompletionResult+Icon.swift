//
//  TKAutocompletionResult+Icon.swift
//  TripKit
//
//  Created by Adrian Schönig on 17/8/21.
//

import Foundation

extension TKAutocompletionResult {
  
  public enum Icon: Int {
    case calendar
    case city
    case contact
    case currentLocation
    case favorite
    case history
    case pin
  }
  
  public static func image(for type: Icon) -> TKImage {
    switch type {
    case .calendar: return TKStyleManager.image(named: "icon-search-calendar")
    case .city: return TKStyleManager.image(named: "icon-search-city")
    case .contact: return TKStyleManager.image(named: "icon-search-contact")
    case .currentLocation: return TKStyleManager.image(named: "icon-search-currentlocation")
    case .favorite: return TKStyleManager.image(named: "icon-search-favourite")
    case .history: return TKStyleManager.image(named: "icon-search-history")
    case .pin: return TKStyleManager.image(named: "icon-search-pin")
    }
  }
  
}
