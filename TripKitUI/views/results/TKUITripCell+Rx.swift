//
//  TKUITripCell+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 15.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension Reactive where Base: TKUITripCell {
  var model: Binder<TKUITripCell.Model> {
    return Binder(self.base) { cell, model in
      cell.configure(model)
    }
  }
}
