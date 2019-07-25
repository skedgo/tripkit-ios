//
//  TKUIDeparturesAccessoryView.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 06.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

class TKUIDeparturesAccessoryView: UIView {

  @IBOutlet weak var timeButton: UIButton!
  @IBOutlet weak var customActionStack: UIStackView!
  
  private var disposeBag = DisposeBag()
  
  static func newInstance() -> TKUIDeparturesAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUIDeparturesAccessoryView", owner: nil, options: nil)!.first as? TKUIDeparturesAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    timeButton.setTitle(nil, for: .normal)
  }
  
  func setCustomActions(_ actions: [TKUIDeparturesCardAction], for model: [TKUIStopAnnotation], card: TKUIDeparturesCard) {
    disposeBag = DisposeBag()
    
    customActionStack.arrangedSubviews.forEach(customActionStack.removeArrangedSubview)
    customActionStack.removeAllSubviews()
    
    let buttons = actions.map { action -> UIButton in
      let button = UIButton(type: .custom)
      button.accessibilityLabel = action.title
      button.setImage(action.icon, for: .normal)
      button.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
      
      button.rx.tap
        .subscribe(onNext: { [weak card, unowned button] in
          guard let card = card else { return }
          let update = action.handler(card, model, button)
          if update {
            button.accessibilityLabel = action.title
            button.setImage(action.icon, for: .normal)
          }
        })
        .disposed(by: disposeBag)
      
      return button
    }
    buttons.forEach(customActionStack.addArrangedSubview)
  }
  
}
