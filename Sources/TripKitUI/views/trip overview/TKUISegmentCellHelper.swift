//
//  TKUISegmentCellHelper.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 04.05.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import TGCardViewController

import TripKit

enum TKUISegmentCellHelper {
  
  @MainActor
  static func buildView<Card: TGCard, Model>(for action: TKUICardAction<Card, Model>, model: Model, for card: Card, tintColor: UIColor = .tkLabelPrimary, disposeBag: DisposeBag) -> UIView {
    let button = UIButton(configuration: .bordered())
    button.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    button.setTitleColor(tintColor, for: .normal)
    button.tintColor = tintColor

    // We could add an icon here, too, but that's not yet in the style guide
    // button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: -4)
    // button.setImage(action.icon, for: .normal)

    button.setTitle(action.title, for: .normal)
    button.accessibilityLabel = action.accessibilityLabel
    button.rx.tap
      .subscribe(onNext: { [unowned card] in
        DispatchQueue.main.async {
          let update = action.handler(action, card, model, button)
          if update {
            button.setTitle(action.title, for: .normal)
            button.accessibilityLabel = action.accessibilityLabel
          }
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

@available(iOS 17.0, *)
#Preview {
  TKUISegmentCellHelper.buildView(
    for: TKUICardAction(
      title: "Open in",
      icon: UIImage(systemName: "app")!,
      handler: { _, _, _, _ in false }
    ),
    model: String(),
    for: TGCard(title: .none),
    tintColor: .tkLabelPrimary,
    disposeBag: .init()
  )
}
