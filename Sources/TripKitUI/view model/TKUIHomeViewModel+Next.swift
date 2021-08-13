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
    case push(TGCard)

    case present(UIViewController, inNavigationController: Bool = false)

    /// Use this for the home card to decide what to do when selecing the provided annotation by the provided component.
    /// The home card will take action according to how it's `selectionMode` is set.
    case handleSelection(MKAnnotation, component: TKUIHomeComponentViewModel? = nil)

    /// Shows the user interface to customize the home card, which let's users re-order and toggle
    /// individual home card components.
    @available(iOS 13.0, *)
    case showCustomizer

    /// Hides the home card component of the matching identifier.
    @available(iOS 13.0, *)
    case hideSection(identifier: String)
    
    case success
  }
}

extension TKUIHomeViewModel {
  
  /// Actions that the view model handles; based on `TKUIHomeCard.ComponentAction`
  enum NextAction {
    case push(TGCard)
    
    case present(UIViewController, inNavigationController: Bool)
    
    @available(iOS 13.0, *)
    case showCustomizer([TKUIHomeCard.CustomizedItem])

    /// Use this for the home card to decide what to do when selecing the provided annotation by the provided component.
    /// The home card will take action according to how it's `selectionMode` is set.
    case handleSelection(MKAnnotation, component: TKUIHomeComponentViewModel? = nil)
    
    /// Use this to handle autocompletion providers' trigger actions. Call the handler and
    /// subscribe to the `Single` that it is returning and if that emits a `true`, call
    /// refresh on the home card.
    case handleAction(handler: (UIViewController) -> Single<Bool>)
  }

  static func buildNext(for componentActions: Signal<TKUIHomeCard.ComponentAction>, customization: Observable<[TKUIHomeCard.CustomizedItem]>) -> Signal<NextAction> {
    componentActions.asObservable()
      .withLatestFrom(customization) { ($0, $1) }
      .compactMap(Self.buildNext(for:customization:))
      .asSignal(onErrorSignalWith: .empty())
  }

  
  static func buildNext(for componentAction: TKUIHomeCard.ComponentAction, customization: [TKUIHomeCard.CustomizedItem]) -> NextAction? {
    switch componentAction {
    case let .push(card):
      return .push(card)
    case let .present(controller, inNavigator):
      return .present(controller, inNavigationController: inNavigator)
    case let .handleSelection(annotation, component):
      return .handleSelection(annotation, component: component)
    case .showCustomizer:
      guard #available(iOS 13.0, *) else { preconditionFailure() }
      return .showCustomizer(customization)
    case .hideSection(let identifier):
      TKUIHomeCard.hideComponent(id: identifier)
      return nil
    case .success:
      return nil
    }
  }
  
}
