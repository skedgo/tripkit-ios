//
//  TKUIHomeViewModel+Next.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift

public enum TKUIHomeCardNextAction {
  
  case push(TGCard)
  
  case present(UIViewController)
  
  /// Use this for the home card to decide what to do when selecing the provided annotation by the provided component.
  /// The home card will take action according to how it's `selectionMode` is set.
  case handleSelection(MKAnnotation, component: TKUIHomeComponentViewModel? = nil)
  
  /// Use this to handle autocompletion providers' trigger actions. Call the handler and
  /// subscribe to the `Single` that it is returning and if that emits a `true`, call
  /// refresh on the home card.
  case handleAction(handler: (UIViewController) -> Single<Bool>)
  
}
