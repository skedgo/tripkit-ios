//
//  TKUITimePickerSheet+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 3/11/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension TKUITimePickerSheet {
  
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    public var incrementInterval: Int = 1
    
    public var allowsASAP: Bool = true
  }
  
}
