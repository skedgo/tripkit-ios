//
//  TKSettings+Rx.swift
//  TripKit
//
//  Created by Adrian Schönig on 04.05.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift

import TripKit

extension Reactive where Base == TKSettings {
  
  public static var hiddenModeIdentifiers: Observable<Set<String>> {
    let hidden = UserDefaults.shared.rx.observe([String].self, TKSettings.DefaultsKey.hidden.rawValue)
    
    return hidden
      .startWith([])
      .map { _ in TKSettings.hiddenModeIdentifiers }
  }
  
}
