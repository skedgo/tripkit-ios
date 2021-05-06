//
//  TKUISegmentCellHelper.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.05.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift

enum TKUISegmentCellHelper {
  
  static func buildView(for action: TKUICardAction<TKUITripOverviewCard, TKSegment>, model: TKSegment, for card: TKUITripOverviewCard, tintColor: UIColor, disposeBag: DisposeBag) -> UIView {
    let button = UIButton(type: .custom)
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    button.setTitleColor(tintColor, for: .normal)

    // We could add an icon here, too, but that's not yet in the style guide
    // button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
    // button.setImage(action.icon, for: .normal)

    button.setTitle(action.title, for: .normal)
    button.rx.tap
      .subscribe(onNext: { [unowned card] in
        let update = action.handler(action, card, model, button)
        if update {
          button.setTitle(action.title, for: .normal)
        }
      })
      .disposed(by: disposeBag)
    return button
  }
  
}

extension UIStackView {
  func resetViews(_ views: [UIView]) {
    arrangedSubviews.forEach(removeArrangedSubview)
    subviews.forEach { $0.removeFromSuperview() }
    views.forEach(addArrangedSubview)
    isHidden = views.isEmpty
  }
}
