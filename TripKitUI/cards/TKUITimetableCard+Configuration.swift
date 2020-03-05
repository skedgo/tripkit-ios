//
//  TKUITimetableCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

public extension TKUITimetableCard {
  
  /// Configurtion of any `TKUITimetableCard`. Use this to add custom
  /// actions.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUITimetableCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    // MARK: - Customising timetable actions
    
    /// Set this to add a list of action buttons to a timeable card.
    ///
    /// Called when a timetable card gets presented.
    public var timetableActionsFactory: (([TKUIStopAnnotation]) -> [TKUICardAction])?

    /// This controls whether the title is visible underneath an action icon.
    ///
    /// The default is `false`, which means actions are displayed as icons
    /// only. We recommend that choosing an action icon that is immediately
    /// obvious what it does and avoids having to set this to `true`. If this
    /// must be set to `true`, we recommend that the titles for your actions
    /// are short, otherwise, some of the titles may be truncated.
    ///
    /// - note: This only applies to actions that are arranged in a compact
    ///     layout
    public var showTimetableActionTitle: Bool = false
  }
  
}
