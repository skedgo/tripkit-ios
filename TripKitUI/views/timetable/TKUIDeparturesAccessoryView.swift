//
//  TKUIDeparturesAccessoryView.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 06.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIDeparturesAccessoryView: UIView {
  
  @IBOutlet weak var serviceCollectionView: UICollectionView!
  
  @IBOutlet weak var customActionStack: UIStackView!

  @IBOutlet weak var bottomBar: UIView!
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var timeButton: UIButton!
    
  static func newInstance() -> TKUIDeparturesAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUIDeparturesAccessoryView", owner: nil, options: nil)!.first as? TKUIDeparturesAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    bottomBar.backgroundColor = .tkBackgroundSecondary
    
    // Apply default style, removing the search bar's background
    TKStyleManager.style(searchBar)

    searchBar.placeholder = Loc.Search
    searchBar.searchTextField.backgroundColor = .tkBackground

    timeButton.setTitle(nil, for: .normal)
  }
  
  func setCustomActions(_ actions: [TKUIDeparturesCardAction], for model: [TKUIStopAnnotation], card: TKUIDeparturesCard) {
    customActionStack.arrangedSubviews.forEach(customActionStack.removeArrangedSubview)
    customActionStack.removeAllSubviews()
    
    customActionStack.isHidden = actions.isEmpty
    
    for action in actions {
      let actionView = TKUIDeparturesActionView.newInstance()
      actionView.imageView.image = action.icon
      actionView.label.text = action.title
      actionView.bold = action.style == .bold
      actionView.onTap = { [weak card, unowned actionView] sender in
        guard let card = card else { return }
        let update = action.handler(card, model, sender)
        if update {
          actionView.imageView.image = action.icon
          actionView.label.text = action.title
        }
      }
      customActionStack.addArrangedSubview(actionView)
    }
  }
  
}
