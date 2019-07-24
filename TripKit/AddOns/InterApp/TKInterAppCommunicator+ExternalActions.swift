//
//  TKInterAppCommunicator+ExternalActions.swift
//  TripKitInterApp-iOS
//
//  Created by Adrian Schönig on 23.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

extension TKInterAppCommunicator {
  
  public enum ExternalActionType {
    case phone
    case message
    case website
    case appDownload
    case appDeepLink
    case ticket
  }
  
  public struct ExternalAction: Equatable {
    public static func == (lhs: TKInterAppCommunicator.ExternalAction, rhs: TKInterAppCommunicator.ExternalAction) -> Bool {
      return lhs.identifier == rhs.identifier
    }
    
    let action: TKInterAppIdentifier

    public let title: String
    public let type: ExternalActionType
    public var identifier: AnyHashable { return action }

    let handler: TKInterAppExternalActionHandler
  }
  
  static var defaultHandlers: [TKInterAppExternalActionHandler] = [
    TKPhoneActionHandler(), TKSMSActionHandler(), TKWebActionHandler()
  ]
  
  public func registerExternalActionHandlers(_ handlers: [TKInterAppExternalActionHandler]) {
    self.handlers.append(contentsOf: handlers)
  }
  
  
  @objc(canHandleExternalActions:)
  public func canHandleExternalActions(for segment: TKSegment) -> Bool {
    guard let actions = segment.bookingExternalActions() else { return false }
    return actions.first { self.titleForExternalAction($0) != nil } != nil
  }
  
  public func externalActions(for segment: TKSegment) -> [ExternalAction] {
    guard let externalActions = segment.bookingExternalActions() else { return [] }
    
    // First we build the actions, sorting them priority and dealing with the
    // case where multiple actions can be handled by the same handler (and
    // we'd only want to show one then)
    return self.handlers
      .compactMap { $0.handledAction(outOf: externalActions) }
      .sorted { $0.handler.priority.rawValue > $1.handler.priority.rawValue }
  }
  
  private func titleForExternalAction(_ action: String) -> String? {
    guard let handler = handlers.first(where: { $0.canHandle(action) }) else { return nil }
    return handler.title(for: action)
  }
  
  /**
   This will handle the external actions of the specified segments either by launching the external app (if there's only one action) or by presenting a sheet of actions to take for the user.
   @param segment A segment for which `canHandleExternalActions` returns YES
   @param presenter A controller to present the optional action sheet on
   @param sender An optional sender on which to anchor the optional action sheet
   @param completion Called when any action is triggered.
   */
  @objc(handleExternalActions:presenter:initiatedBy:completionHandler:)
  public func handleExternalActions(for segment: TKSegment, presenter: UIViewController, sender: Any?, completion: ((String) -> Void)?) {
    
    let handlers = self.externalActions(for: segment)
    guard !handlers.isEmpty else { return }
    
    if handlers.count == 1, let handled = handlers.first {
      performExternalAction(handled.action, for: segment, presenter: presenter, sender: sender)
      completion?(handled.action)
      return
    }
    
    let actions = TKActions()
    handlers.forEach { handled in
      actions.addAction(handled.title) {
        handled.handler.performAction(for: handled.action, segment: segment, presenter: presenter, sender: sender)
        completion?(handled.action)
      }
    }
    actions.hasCancel = true
    actions.showForSender(sender, in: presenter)
  }
  
  @objc(performExternalAction:forSegment:presenter:initiatedBy:)
  public func performExternalAction(_ action: String, for segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    guard let handler = handlers.first(where: { $0.canHandle(action) }) else { assertionFailure(); return }
    handler.performAction(for: action, segment: segment, presenter: presenter, sender: sender)
  }
  
  public func perform(_ action: ExternalAction, for segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    action.handler.performAction(for: action.action, segment: segment, presenter: presenter, sender: sender)
  }

  
}

fileprivate extension TKInterAppExternalActionHandler {
  
  func handledAction(outOf actions: [TKInterAppIdentifier]) -> TKInterAppCommunicator.ExternalAction? {
    guard let action = actions.first(where: canHandle) else { return nil }
    let title = self.title(for: action)
    return TKInterAppCommunicator.ExternalAction(action: action, title: title, type: type, handler: self)
  }
  
}
