//
//  TKUIServiceTitleView+Rx.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 19.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

extension Reactive where Base: TKUIServiceTitleView {
  var model: Binder<TKUIDepartureCellContent> {
    return Binder(self.base) { header, model in
      header.configure(with: model)
    }
  }
}
