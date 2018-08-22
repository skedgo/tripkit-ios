//
//  TKEventTrackable.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 22/8/18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// This protocol provides a set of methods that external types can use
/// to specify how certain events originated from TripKitUI are tracked.
///
/// Many TripKitUI types have an `eventTrackingDelegate` which is of type
/// `TKUIEventTrackable`. An example usage is thus for an external type
/// to conform to `TKUIEventTrackable` and assign itself to this delegate.
/// When trackable events are triggered, the delegate will be notified to
/// execute any custom tracking actions.
///
/// Note, it's not necessary for conforming types to implement all the
/// protocol methods. However, the default implementation for all methods
/// does nothing.
public protocol TKUIEventTrackable {
  
  func trackScreen(named: String)
  
}

extension TKUIEventTrackable {
  
  public func trackScreen(named: String) { }
  
}
