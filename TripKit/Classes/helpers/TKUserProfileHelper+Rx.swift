//
//  TKUserProfileHelper+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 04.05.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

extension Reactive where Base == TKUserProfileHelper {
  
  public static var hiddenAndMinimizedModeIdentifiers: Observable<Set<TKUserProfileHelper.Identifier>> {
    let hidden = UserDefaults.shared.rx.observe([TKUserProfileHelper.Identifier].self, TKUserProfileHelper.DefaultsKey.hidden.rawValue)
    let minimized = UserDefaults.shared.rx.observe([TKUserProfileHelper.Identifier].self, TKUserProfileHelper.DefaultsKey.minimized.rawValue)
    
    return Observable.merge(hidden, minimized)
      .startWith([])
      .map { _ in
        TKUserProfileHelper.hiddenAndMinimizedModeIdentifiers
      }
  }
  
}
