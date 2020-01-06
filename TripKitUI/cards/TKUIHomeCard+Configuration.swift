//
//  TKUIHomeCard+Configuration.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 2/12/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension TKUIHomeCard {
  
  struct Configuration {
    // We don't want this to be initialised.
    private init() {}
    
    static let empty = Configuration()
    
    /// Set this to add a list of autocompletion providers to use.
    ///
    /// The default providers, if none is provided, are Apple and SkedGo geocoders.
    public var autocompletionDataProviders: [TKAutocompleting]?
    
    /// Set this to add a tap-action to a non-stop map annotation in the home
    /// card. The closure returns a boolean indicating whether other annotations
    /// should be hidden when the selection is made.
    ///
    /// Handler will be called when the user taps a non-stop annotation in the
    /// map. You can, for example, use this to present a detailed view of the
    /// location.
    public var presentLocationHandler: ((TKUIHomeCard, TKModeCoordinate) -> Bool)?
  }
  
}
