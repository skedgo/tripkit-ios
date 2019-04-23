//
//  TKPhoneActionHandler.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 17.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

class TKPhoneActionHandler: TKInterAppExternalActionHandler {
  
  private let canCall = UIApplication.shared.canOpenURL(URL(string: "tel:")!)
  
  let priority: TKInterAppExternalActionPriority = .low
  
  func canHandle(_ string: TKInterAppIdentifier) -> Bool {
    return canCall && string.hasPrefix("tel:")
  }
  
  func title(for identifier: TKInterAppIdentifier) -> String {
    if let nameRange = identifier.range(of: "name="), let name = identifier[nameRange.upperBound...].removingPercentEncoding {
      return Loc.Call(service: name)
    } else {
      return Loc.Call
    }
  }
  
  func performAction(for identifier: TKInterAppIdentifier, segment: TKSegment, presenter: UIViewController, sender: Any?) {
    let cleaned = identifier.replacingOccurrences(of: " ", with: "-")
    guard let callURL = URL(string: cleaned) else { assertionFailure(); return }
    UIApplication.shared.open(callURL)
  }

}
