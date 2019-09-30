//
//  TKSMSActionHandler.swift
//  TripKit-iOS
//
//  Created by Adrian Schönig on 17.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import MessageUI

import TripKit

/// Handler for `sms:` actions, bringing up the Messages app,
/// optionally pre-filling a message.
///
/// - warning: This only works if you add the `sms` URL scheme to the
///           `LSApplicationQueriesSchemes`of your app's `Info.plist`, e.g.,:
///
/// ```
/// <key>LSApplicationQueriesSchemes</key>
/// <array>
///   <string>sms</string>
///   ...
/// </array>
/// ```
public class TKSMSActionHandler: TKInterAppExternalActionHandler {
  
  private let canSendSMS = UIApplication.shared.canOpenURL(URL(string: "sms:")!)
  
  public let priority: TKInterAppExternalActionPriority = .low
  
  public let type: TKInterAppCommunicator.ExternalActionType = .message
  
  public func canHandle(_ string: TKInterAppIdentifier) -> Bool {
    return canSendSMS && string.hasPrefix("sms:")
  }
  
  public func title(for identifier: TKInterAppIdentifier) -> String {
    return Loc.SendSMS
  }
  
  public func performAction(for identifier: TKInterAppIdentifier, segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    let raw = identifier.replacingOccurrences(of: "sms:", with: "")
    let brokenUp = raw.components(separatedBy: "?")
    guard let recipient = brokenUp.first else {
      assertionFailure(); return
    }
    let message = brokenUp.count > 1 ? brokenUp.last : nil
    
    let composer = MFMessageComposeViewController()
    composer.messageComposeDelegate = ComposerDelegate.shared
    composer.recipients = [recipient]
    composer.body = message
    
    presenter.present(composer, animated: true)
  }
  
}

fileprivate class ComposerDelegate: NSObject {
  static let shared = ComposerDelegate()
  
  private override init() {
    super.init()
  }
}

extension ComposerDelegate: MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.presentingViewController?.dismiss(animated: true)
  }
}
