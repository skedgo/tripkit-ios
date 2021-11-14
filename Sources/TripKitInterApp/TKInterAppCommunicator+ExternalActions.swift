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

    public var title: String
    public var accessibilityLabel: String
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
  
  /// Checks if the communication can handle any of the segment's available external actions, which depends
  /// both on whether there's a relevant handler registered for it *and* whether the device is capable, too.
  ///
  /// - Parameter segment: A segment
  /// - Returns: Whether the action can be handled, i.e., triggering `handleExternalActions` will succeed.
  @objc(canHandleExternalActions:)
  public func canHandleExternalActions(for segment: TKSegment) -> Bool {
    guard let actions = segment.bookingExternalActions else { return false }
    return actions.contains { self.canHandleExternalAction($0) }
  }
  
  /// Checks if the communication can handle the provided action, which depends both on whether
  /// there's a relevant handler registered for it *and* whether the device is capable, too.
  ///
  /// - Parameter action: An action string, as defined by SkedGo's backend
  /// - Returns: Whether the action can be handled, i.e., triggering `performExternalAction` will succeed.
  public func canHandleExternalAction(_ action: String) -> Bool {
    return handlers.contains { $0.canHandle(action) }
  }
  
  /// Determines external actions for the provided segment
  ///
  /// - Parameter segment: A segment
  /// - Returns: Available actions, can be empty
  public func externalActions(for segment: TKSegment) -> [ExternalAction] {
    guard let externalActions = segment.bookingExternalActions else { return [] }
    
    // First we build the actions, sorting them priority and dealing with the
    // case where multiple actions can be handled by the same handler (and
    // we'd only want to show one then)
    let actions: [ExternalAction] = self.handlers
      .compactMap { $0.handledAction(outOf: externalActions) }
      .sorted { $0.handler.priority.rawValue > $1.handler.priority.rawValue }
    
    // If we only have one action, we prefer the title suggested by the backend
    // otherwise keep the per-handler titles to not duplicate them
    if actions.count == 1, var action = actions.first, let suggestedTitle = segment.bookingTitle {
      action.title = suggestedTitle
      action.accessibilityLabel = segment.bookingAccessibilityLabel ?? suggestedTitle
      return [action]
    } else {
      return actions
    }
  }
  
  /// This will handle the external actions of the specified segments either by launching the external app (if there's only one action) or by presenting a sheet of actions to take for the user.
  ///
  /// - Parameters:
  ///   - segment: A segment for which `canHandleExternalActions` returns `true`
  ///   - presenter: A controller to present the optional action sheet on
  ///   - sender: An optional sender on which to anchor the optional action sheet
  ///   - completion: Called when any action is triggered.
  @objc(handleExternalActions:presenter:initiatedBy:completionHandler:)
  public func handleExternalActions(for segment: TKSegment, presenter: UIViewController, sender: Any?, completion: ((String) -> Void)?) {
    
    let handlers = self.externalActions(for: segment)
    guard !handlers.isEmpty else { return }
    
    if handlers.count == 1, let handled = handlers.first {
      performExternalAction(handled.action, for: segment, presenter: presenter, sender: sender)
      completion?(handled.action)
      return
    }
    
    let actions = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    handlers.forEach { handled in
      actions.addAction(.init(title: handled.title, style: .default) { _ in
        handled.handler.performAction(for: handled.action, segment: segment, presenter: presenter, sender: sender)
        completion?(handled.action)
      })
    }
    actions.addAction(.init(title: Loc.Cancel, style: .cancel, handler: nil))
    presenter.present(actions, animated: true)
  }
  
  /// This will perform the provided external action, taking information from the (optionally) provided segment
  ///
  /// - Parameters:
  ///   - action: An action for which `canHandleExternalAction` returns `true`
  ///   - segment: Optional segment for things like start/end locations to pass to a turn-by-turn app
  ///   - presenter: A controller to present the optional action sheet on
  ///   - sender: An optional sender on which to anchor views as required by the handler
  @objc(performExternalAction:forSegment:presenter:initiatedBy:)
  public func performExternalAction(_ action: String, for segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    guard let handler = handlers.first(where: { $0.canHandle(action) }) else { assertionFailure(); return }
    handler.performAction(for: action, segment: segment, presenter: presenter, sender: sender)
  }
  
  /// This will perform the provided external action, taking information from the (optionally) provided segment
  ///
  /// - Parameters:
  ///   - action: An action for which `canHandleExternalAction` returns `true`
  ///   - segment: Optional segment for things like start/end locations to pass to a turn-by-turn app
  ///   - presenter: A controller to present the optional action sheet on
  ///   - sender: An optional sender on which to anchor views as required by the handler
  public func perform(_ action: ExternalAction, for segment: TKSegment?, presenter: UIViewController, sender: Any?) {
    action.handler.performAction(for: action.action, segment: segment, presenter: presenter, sender: sender)
  }

}

fileprivate extension TKInterAppExternalActionHandler {
  
  func handledAction(outOf actions: [TKInterAppIdentifier]) -> TKInterAppCommunicator.ExternalAction? {
    guard let action = actions.first(where: canHandle) else { return nil }
    let title = self.title(for: action)
    return TKInterAppCommunicator.ExternalAction(
      action: action,
      title: title,
      accessibilityLabel: title,
      type: type,
      handler: self
    )
  }
  
}
