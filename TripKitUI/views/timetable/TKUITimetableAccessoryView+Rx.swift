//
//  TKUITimetableAccessoryView+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension Reactive where Base: TKUITimetableAccessoryView {
  var lines: Binder<[TKUITimetableAccessoryView.Line]> {
    return Binder(self.base) { view, model in
      view.lines = model
    }
  }
}
