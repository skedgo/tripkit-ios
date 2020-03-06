//
//  ExampleCustomizer.swift
//  TripKitUIExample
//
//  Created by Kuan Lun Huang on 3/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKitUI

struct ExampleCustomizer {
  
  private init() {}
  
  static func configureCards() {
    configureTimetableCard()
    configureRoutingResultsCard()
  }
  
}

// MARK: - Timetable cards

extension ExampleCustomizer {
  
  private static func configureRoutingResultsCard() {
    
    TKUIRoutingResultsCard.config.initialCardPosition = .collapsed
    TKUIRoutingResultsCard.config.limitToModes = ["pt_pub"]
    
  }
  
  private static func configureTimetableCard() {
    TKUITimetableCard.config.timetableActionsFactory = { stops in
      var actions: [TKUITimetableCard.Action] = []
      if stops.count == 1, let stop = stops.first {
        actions.append(buildFavoriteStopAction(stop: stop))
      }
      return actions
    }
  }
  
  private static func buildFavoriteStopAction(stop: TKUIStopAnnotation) -> TKUITimetableCard.Action {
    
    func isFavorite() -> Bool { InMemoryFavoriteManager.shared.hasFavorite(for: stop) }
    func title() -> String { isFavorite() ? "Remove Favorite" : "Add Favorite" }
    func icon() -> UIImage { isFavorite() ? UIImage(named: "favorite")! : UIImage(named: "favorite-outline")! }
    
    return TKUITimetableCard.Action(
      title: title(), icon: icon()
    ) { [unowned stop] _, _, _, _ in
      InMemoryFavoriteManager.shared.toggleFavorite(for: stop)
      return true
    }
  }
}
