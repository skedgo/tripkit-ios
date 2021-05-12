//
//  TGCardView+Rx.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 20.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import TGCardViewController

extension Reactive where Base: TGCardView {
  var titles: Binder<(title: String, subtitle: String?)> {
    return Binder(self.base) { view, titles in
      view.updateDefaultTitle(title: titles.title, subtitle: titles.subtitle)
    }
  }
}
