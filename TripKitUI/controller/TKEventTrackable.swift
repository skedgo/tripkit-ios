//
//  TKEventTrackable.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 22/8/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public protocol TKEventTrackable {
  
  func trackScreen(named: String)
  
}

extension TKEventTrackable {
  
  public func trackScreen(named: String) { }
  
}
