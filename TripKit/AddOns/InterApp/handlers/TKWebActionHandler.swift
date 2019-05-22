//
//  TKWebActionHandler.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 17.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

/// Handler for `http:` and `https:` actions, which refers back to the default
/// handler in `TKInterAppCommunicator.openURLHandler`
public class TKWebActionHandler: TKInterAppExternalActionHandler {
  
  public let priority: TKInterAppExternalActionPriority = .low
  
  public func canHandle(_ string: TKInterAppIdentifier) -> Bool {
    return string.hasPrefix("http:") || string.hasPrefix("https:")
  }
  
  public func title(for identifier: TKInterAppIdentifier) -> String {
    return Loc.ShowWebsite
  }
  
  public func performAction(for identifier: TKInterAppIdentifier, segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    guard let url = URL(string: identifier) else { assertionFailure(); return }
    TKInterAppCommunicator.shared.openURLHandler(url, self.title(for: identifier), presenter)
  }
  
}
