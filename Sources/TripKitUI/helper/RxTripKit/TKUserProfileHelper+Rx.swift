//
//  TKUserProfileHelper+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 04.05.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension Reactive where Base == TKUserProfileHelper {
  
  public static var hiddenModeIdentifiers: Observable<Set<TKUserProfileHelper.Identifier>> {
    let hidden = UserDefaults.shared.rx.observe([TKUserProfileHelper.Identifier].self, TKUserProfileHelper.DefaultsKey.hidden.rawValue)
    
    return hidden
      .startWith([])
      .map { _ in
        TKUserProfileHelper.hiddenModeIdentifiers
      }
  }
  
}
