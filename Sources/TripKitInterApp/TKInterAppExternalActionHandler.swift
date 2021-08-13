//
//  TKInterAppExternalActionHandler.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 17.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit

public typealias TKInterAppIdentifier = String

public enum TKInterAppExternalActionPriority: Int {
  case high   = 10 // Recommended for installed apps
  case medium = 5  // Recommended for apps that can be installed
  case low    = 1  // Recommended for non-app-based actions
}

public protocol TKInterAppExternalActionHandler {
  
  var priority: TKInterAppExternalActionPriority { get }
  
  var type: TKInterAppCommunicator.ExternalActionType { get }
  
  func canHandle(_ string: TKInterAppIdentifier) -> Bool
  
  func title(for identifier: TKInterAppIdentifier) -> String
  
  func performAction(for identifier: TKInterAppIdentifier, segment: TKSegment?, presenter: UIViewController, sender: Any?)
  
}
