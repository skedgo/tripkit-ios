//
//  TKUIHomeViewModel+Next.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public enum TKUIHomeCardNextAction {
  
  case push(TGCard)
  
  case present(UIViewController)
  
  /// Use this for the home card to decide what to do when selecing the provided annotation by the provided component.
  /// The home card will take action according to how it's `selectionMode` is set.
  case handleSelection(MKAnnotation, component: TKUIHomeComponentViewModel)
  
}
