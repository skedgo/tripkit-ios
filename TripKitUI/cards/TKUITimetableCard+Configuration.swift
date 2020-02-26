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
    
    /// Set this to add a list of action buttons to a timeable card.
    ///
    /// Called when a timetable card gets presented.
    public var timetableActionsFactory: (([TKUIStopAnnotation]) -> [TKUITimetableCardAction])?
    
    /// You can use this to force a compact layout for timetable actions.
    ///
    /// By default, if there are fewer than two actions provided through
    /// `timetableActionsFactory`, a long layout (i.e., icon and
    /// label are stacked horizontally) is used. If there are more than two
    /// actions, then a compact layout (i.e., icon and labels are stacked
    /// vertically) is used. 
    public var forceCompactActionsLayout: Bool = false

    /// Set this to true if the services' transit icons should get the colour
    /// of the respective line.
    ///
    /// Default to `false`.
    public var colorCodeTransitIcons: Bool = false
  }
  
}
