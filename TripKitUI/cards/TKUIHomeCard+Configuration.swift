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
    
    public var autocompletionDataProviders: [TKAutocompleting]?
  }
  
}
