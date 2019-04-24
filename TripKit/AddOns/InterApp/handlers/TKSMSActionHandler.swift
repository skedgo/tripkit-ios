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

class TKSMSActionHandler: TKInterAppExternalActionHandler {
  
  private let canSendSMS = UIApplication.shared.canOpenURL(URL(string: "sms:")!)
  
  let priority: TKInterAppExternalActionPriority = .low
  
  func canHandle(_ string: TKInterAppIdentifier) -> Bool {
    return canSendSMS && string.hasPrefix("sms:")
  }
  
  func title(for identifier: TKInterAppIdentifier) -> String {
    return Loc.SendSMS
  }
  
  func performAction(for identifier: TKInterAppIdentifier, segment: TKSegment?, presenter: UIViewController, sender: Any?) {
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
