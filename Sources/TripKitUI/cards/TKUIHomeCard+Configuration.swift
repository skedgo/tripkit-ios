//
//  TKUIHomeCard+Configuration.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 2/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

import TripKit

public extension TKUIHomeCard {
  
  enum SelectionMode {
    /// Home selection will always be passed to the home map manager, for that to handle it.
    case selectOnMap
    
    /// Execute the provided callback on tap; the component will only be set if selected via
    /// the card itself and not something on the map. The closure returns a boolean indicating
    /// whether other annotations should be hidden when the selection is made.
    case callback((TKAutocompletionSelection, TKUIHomeComponentViewModel?) -> Bool)
    
    /// Default handling shows timetable for stops and routing results for others
    case `default`
  }
  
  enum VoiceOverMode {
    case searchBar
    
    case routeButton
  }
  
  struct Configuration {
    // We don't want this to be initialised.
    private init() {}
    
    static let empty = Configuration()
    
    /// Set this to indicate if permission to access location services should be
    /// requested when the card is loaded. When setting to `true`, the map
    /// is zoomed to a user's current location and begins displaying nearby
    /// stops and locations.
    ///
    /// The default value is `true`
    public var requestLocationServicesOnLoad: Bool = true
    
    /// Set this to place actionable items on the map view. Items are arranged
    /// vertically. 
    public var topMapToolbarItems: [UIView]?
    
    /// Set this to add a list of autocompletion providers to use.
    ///
    /// The default providers, if none is provided, are Apple and SkedGo geocoders.
    public var autocompletionDataProviders: [TKAutocompleting]?
    
    /// Set this to specify what view model classes can be used by the home card
    /// to build its content
    public var componentViewModelClasses: [TKUIHomeComponentViewModel.Type] = []

    /// Set this to `true` if your components aren't customizable and they should always be ordered
    /// as defined in ``componentViewModelClasses``.
    public var ignoreComponentCustomization: Bool = false

    /// Set this to customise what should happen if map content or an autocompletion
    /// result is tapped (or whenever one of your component view models calls `.handleSelection`)
    public var selectionMode: SelectionMode = .default
    
    /// Set where the initial VoiceOver focus should be. Defaults to `.searchBar`
    public var voiceOverStartMode: TKUIHomeCard.VoiceOverMode = .searchBar
    
    /// Determines if a  `TKUIRoutingQueryInputCard` starts with a focus on the destination field,
    /// if activated through the direction button in the home card.
    public var directionButtonStartsQueryInputInDestinationMode: Bool = true
  }
  
}
