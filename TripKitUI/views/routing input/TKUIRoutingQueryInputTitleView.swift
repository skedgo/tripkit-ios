//
//  TKUIRoutingQueryInputTitleView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 23.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

import RxSwift
import RxCocoa

class TKUIRoutingQueryInputTitleView: UIView {
  
  static func newInstance() -> TKUIRoutingQueryInputTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUIRoutingQueryInputTitleView", owner: self, options: nil)?.first as! TKUIRoutingQueryInputTitleView
  }
  
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var routeButton: UIButton!
  
  @IBOutlet weak var fromSearchBar: UISearchBar!
  @IBOutlet weak var toSearchBar: UISearchBar!
  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!

  @IBOutlet weak var dottedLineView: UIImageView!
  @IBOutlet weak var separatorView: UIView!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    separatorView.backgroundColor = .tkSeparatorSubtle
    
    func style(_ searchBar: UISearchBar) {
      // Don't show search icon, i.e., the magnifying glass
      searchBar.setImage(nil, for: .search, state: .normal)
      TKStyleManager.style(searchBar, includingBackground: false) { textField in
        // This is to remove the space occupied by the magnifying glass.
        textField.leftView = UIImageView()
        
        // Always show clear button, see https://redmine.buzzhives.com/issues/4595
        textField.clearButtonMode = .always
      }
    }
    style(fromSearchBar)
    style(toSearchBar)
    fromSearchBar.placeholder = Loc.StartLocation
    toSearchBar.placeholder = Loc.EndLocation
    
    fromButton.backgroundColor = .clear
    fromButton.tintColor = .tkAppTintColor
    toButton.backgroundColor = .clear
    toButton.tintColor = .tkAppTintColor
  }
  
}

extension Reactive where Base == TKUIRoutingQueryInputTitleView {
  var originDestination: Binder<(origin: String, destination: String)> {
    return Binder(self.base) { view, od in
      view.fromSearchBar.text = od.origin
      view.toSearchBar.text = od.destination
    }
  }

  var searchMode: Binder<TKUIRoutingResultsViewModel.SearchMode> {
    return Binder(self.base) { view, mode in
      view.fromButton.isSelected = mode == .origin
      view.toButton.isSelected = mode == .destination
      
      switch mode {
      case .origin:
        view.fromSearchBar.becomeFirstResponder()
      case .destination:
        view.toSearchBar.becomeFirstResponder()
      }
    }
  }
  
  var searchInput: Observable<(TKUIRoutingResultsViewModel.SearchMode, String)> {
    return Observable.merge([
      base.fromSearchBar.rx.editedText.map { (.origin, $0) },
      base.toSearchBar.rx.editedText.map { (.destination, $0) },
    ])
  }

  var searchText: Observable<String> { searchInput.map { $0.1 } }
  
  var selectedSearchMode: Signal<TKUIRoutingResultsViewModel.SearchMode> {
    return Signal.merge([
      searchInput.map { $0.0 }.asSignal(onErrorSignalWith: .empty()),
        base.fromButton.rx.tap.asSignal().map { .origin },
        base.toButton.rx.tap.asSignal().map { .destination }
      ])
  }
}

fileprivate extension Reactive where Base == UISearchBar {
  var editedText: Observable<String> {
    return text
      .withLatestFrom(isEditing) { ($0, $1) }
      .compactMap { $1 ? $0 : nil }
  }
  
  var isEditing: Observable<Bool> {
    let didBegin = textDidBeginEditing
    let didEnd = textDidEndEditing
    
    return Observable.merge([
        didBegin.map { _ in true },
        didEnd.map { _ in false },
      ])
      .startWith(false)
      .distinctUntilChanged()
  }
}
