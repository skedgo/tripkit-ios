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
      var actions: [TKUITimetableCardAction] = []
      if stops.count == 1, let stop = stops.first {
        actions.append(FavoriteStopAction(stop: stop))
      }
      return actions
    }
    
  }
  
  fileprivate struct FavoriteStopAction: TKUITimetableCardAction {
    let stop: TKUIStopAnnotation
    
    private var isFavorite: Bool {
      return InMemoryFavoriteManager.shared.hasFavorite(for: stop)
    }
    
    var title: String { return isFavorite ? "Remove Favorite" : "Add Favorite" }
    
    var icon: UIImage { return isFavorite ? UIImage(named: "favorite")! : UIImage(named: "favorite-outline")! }
    
    var handler: (TKUITimetableCard, [TKUIStopAnnotation], UIView) -> Bool {
      return { [unowned stop] _, _, _ in
        InMemoryFavoriteManager.shared.toggleFavorite(for: stop)
        return true
      }
    }
  }
  
}


