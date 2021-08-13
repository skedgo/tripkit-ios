//
//  TKInterAppCommunicator.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 23.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

@objc
public class TKInterAppCommunicator: NSObject {
  
  @objc(sharedInstance)
  public static let shared = TKInterAppCommunicator()
  
  var handlers = TKInterAppCommunicator.defaultHandlers
  
  private override init() {
    super.init()
  }
  
  /// Will be called if the user selects an action that requires opening a
  /// website. By default just opens the webpage in Safari.
  public var openURLHandler: (URL, String, UIViewController) -> Void = { url, _, _ in
    UIApplication.shared.open(url)
  }
  
  // Will be called with an iTunes app ID if the user select an action that
  // requires installing an app. By default deep-links into the App Store app
  public var openStoreHandler: (Int, UIViewController) -> Void = { id, _ in
    let urlString = String(format: "https://itunes.apple.com/app/id%d?mt=8", id)
    guard let url = URL(string: urlString) else { assertionFailure(); return }
    UIApplication.shared.open(url)
  }
  
}
