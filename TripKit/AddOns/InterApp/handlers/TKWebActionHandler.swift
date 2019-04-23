//
//  TKWebActionHandler.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 17.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

class TKWebActionHandler: TKInterAppExternalActionHandler {
  
  let priority: TKInterAppExternalActionPriority = .low
  
  func canHandle(_ string: TKInterAppIdentifier) -> Bool {
    return string.hasPrefix("http:") || string.hasPrefix("https:")
  }
  
  func title(for identifier: TKInterAppIdentifier) -> String {
    return Loc.ShowWebsite
  }
  
  func performAction(for identifier: TKInterAppIdentifier, segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    guard let url = URL(string: identifier) else { assertionFailure(); return }
    TKInterAppCommunicator.shared.openURLHandler(url, self.title(for: identifier), presenter)
  }
  
}
