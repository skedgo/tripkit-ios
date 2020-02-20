//
//  TKUIDebugActionHandler.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 20.02.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

/// :nodoc:
@objc
public protocol TKUIDebugActionHandler: class {
  @objc func debugActionCopyPrimaryRequest(_ sender: AnyObject?)
}
