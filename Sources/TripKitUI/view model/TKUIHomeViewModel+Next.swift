//
//  TKUIHomeViewModel+Next.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit
import UIKit

import RxSwift
import struct RxCocoa.Signal
import TGCardViewController

import TripKit

@available(*, unavailable, renamed: "TKUIHomeCard.ComponentAction")
public typealias TKUIHomeCardNextAction = TKUIHomeCard.ComponentAction

extension TKUIHomeCard {
  
  /// Actions that can be triggered by component view models
  public enum ComponentAction {
    case push(TGCard, selection: MKAnnotation? = nil)

    case present(UIViewController, inNavigationController: Bool = false)

    /// Use this for the home card to decide what to do when selecing the provided annotation by the provided component.
    /// The home card will take action according to how it's `selectionMode` is set.
    case handleSelection(TKAutocompletionSelection, component: TKUIHomeComponentViewModel? = nil)

    /// Shows the user interface to customize the home card, which let's users re-order and toggle
    /// individual home card components.
    case showCustomizer

    /// Hides the home card component of the matching identifier.
    case hideSection(identifier: String)
    
    /// A custom handler that should be triggered, providing the home card view controller
    case trigger((UIViewController) -> Void)
    
    case enterSearchMode
    
    case success
  }
}

extension TKUIHomeViewModel {
  
  /// Actions that the view model handles; based on `TKUIHomeCard.ComponentAction`
  enum NextAction {
    case push(TGCard, selection: MKAnnotation?)
    
    case present(UIViewController, inNavigationController: Bool)
    
    case showCustomizer([TKUIHomeCard.CustomizedItem])

    /// Use this for the home card to decide what to do when selecing the provided annotation by the provided component.
    /// The home card will take action according to how it's `selectionMode` is set.
    case handleSelection(TKAutocompletionSelection, component: TKUIHomeComponentViewModel? = nil)
    
    /// Use this to handle autocompletion providers' trigger actions. Call the handler and
    /// subscribe to the `Single` that it is returning and if that emits a `true`, call
    /// refresh on the home card.
    case handleAction(handler: (UIViewController) -> Single<Bool>)
    
    case enterSearchMode
    
    /// A custom handler that should be triggered, providing the home card view controller
    case trigger((UIViewController) -> Void)
  }

  static func buildNext(for componentActions: Signal<TKUIHomeCard.ComponentAction>, customization: Observable<[TKUIHomeCard.CustomizedItem]>) -> Signal<NextAction> {
    componentActions.asObservable()
      .withLatestFrom(customization) { ($0, $1) }
      .compactMap(Self.buildNext(for:customization:))
      .asAssertingSignal()
  }

  
  static func buildNext(for componentAction: TKUIHomeCard.ComponentAction, customization: [TKUIHomeCard.CustomizedItem]) -> NextAction? {
    switch componentAction {
    case let .trigger(handler):
      return .trigger(handler)
    case let .push(card, selection):
      return .push(card, selection: selection)
    case let .present(controller, inNavigator):
      return .present(controller, inNavigationController: inNavigator)
    case let .handleSelection(annotation, component):
      return .handleSelection(annotation, component: component)
    case .showCustomizer:
      return .showCustomizer(customization)
    case .hideSection(let identifier):
      TKUIHomeCard.hideComponent(id: identifier)
      return nil
    case .enterSearchMode:
      return .enterSearchMode
    case .success:
      return nil
    }
  }
  
}
