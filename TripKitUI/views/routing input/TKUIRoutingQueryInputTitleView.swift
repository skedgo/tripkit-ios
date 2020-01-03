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

  @IBOutlet weak var buttonLine: UIView!
  
  private var isAnimatingSwap: Bool = false
  private var onSwapCompletion: (() -> Void)? = nil
  
  fileprivate let switchMode = PublishSubject<TKUIRoutingResultsViewModel.SearchMode>()
  fileprivate let typed = PublishSubject<String>()
  fileprivate let route = PublishSubject<Void>()
  
  private let disposeBag = DisposeBag()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    func style(_ searchBar: UISearchBar) {
      searchBar.backgroundImage = UIImage() // blank
      
      // Don't show search icon, i.e., the magnifying glass
      searchBar.setImage(nil, for: .search, state: .normal)
      
      TKStyleManager.style(searchBar) { textField in
        // This is to remove the space occupied by the magnifying glass.
        textField.leftView = UIImageView()
        
        textField.delegate = self
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
    buttonLine.backgroundColor = .tkSeparatorSubtle
    swapButton.tintColor = .tkLabelSecondary
    
    closeButton.tintColor = .tkAppTintColor
    closeButton.setTitle(Loc.Cancel, for: .normal)
    closeButton.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .body)
    routeButton.tintColor = .tkAppTintColor
    routeButton.setTitle(Loc.Route, for: .normal)
    routeButton.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .body)

    swapButton.addTarget(self, action: #selector(animateSwap), for: .touchUpInside)
    
    fromButton.rx.tap
      .subscribe(onNext: { [weak self] _ in self?.switchMode.onNext(.origin)})
      .disposed(by: disposeBag)

    toButton.rx.tap
      .subscribe(onNext: { [weak self] _ in self?.switchMode.onNext(.destination)})
      .disposed(by: disposeBag)
    
    fromSearchBar.delegate = self
    toSearchBar.delegate = self
  }
  
  func setText(origin: String, destination: String) {
    let update = { [unowned self] in
      self.fromSearchBar.text = origin
      self.toSearchBar.text = destination
    }
    
    if isAnimatingSwap {
      onSwapCompletion = update
    } else {
      update()
    }
  }
  
  func becomeFirstResponder(mode: TKUIRoutingResultsViewModel.SearchMode) {
    guard
      let searchBar = mode == .origin ? fromSearchBar : toSearchBar
      else { return }
    
    let isFirst = searchBar.becomeFirstResponder()
    if #available(iOS 13.0, *) {
      searchBar.searchTextField.selectedTextRange = searchBar.searchTextField.textualRange
    }
  }

  override func resignFirstResponder() -> Bool {
    if fromSearchBar.isFirstResponder {
      return fromSearchBar.resignFirstResponder()
    } else if toSearchBar.isFirstResponder {
      return toSearchBar.resignFirstResponder()
    } else {
      return super.resignFirstResponder()
    }
  }
  
}

// MARK: - UISearchBarDelegate

extension TKUIRoutingQueryInputTitleView: UISearchBarDelegate {
  
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    switch searchBar {
    case fromSearchBar: switchMode.onNext(.origin)
    case toSearchBar: switchMode.onNext(.destination)
    default: assertionFailure()
    }
    
    // Before editing begins, we publish the current search text so that
    // the autocompletion shows immediate results if available.
    typed.onNext(searchBar.text ?? "")
    
    return true
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    // We are publishing the search mode here again because it's possible that
    // the text change was initiated from a search bar that does not match the
    // current search mode, see: https://redmine.buzzhives.com/issues/12017.
    switch searchBar {
    case fromSearchBar: switchMode.onNext(.origin)
    case toSearchBar: switchMode.onNext(.destination)
    default: assertionFailure()
    }
    
    typed.onNext(searchText)
  }
  
}

// MARK: - UITextFieldDelegate

extension TKUIRoutingQueryInputTitleView: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    _ = self.resignFirstResponder()
    
    self.route.onNext(())
    
    return false
  }
}

// MARK: - Animations

extension TKUIRoutingQueryInputTitleView {
  
  @objc
  func animateSwap() {
    rotate(swapButton)
    swapSearchBars()
  }
  
  func rotate(_ view: UIView, up: Bool? = nil) {
    let up = up ?? (view.transform != CGAffineTransform.identity)
    UIView.animate(withDuration: 0.25) {
      if up {
        view.transform = CGAffineTransform.identity
      } else {
        view.transform = CGAffineTransform(rotationAngle: 0.999 * .pi)
      }
    }
  }
  
  func swapSearchBars() {
    let fromFrame = fromSearchBar.frame
    let toFrame = toSearchBar.frame
    
    isAnimatingSwap = true
    
    UIView.animate(
      withDuration: 0.25, delay: 0, options: [.curveEaseInOut],
      animations: {
        self.fromSearchBar.frame = toFrame
        self.toSearchBar.frame = fromFrame

      }, completion: { _ in
        self.fromSearchBar.frame = fromFrame
        self.toSearchBar.frame = toFrame
        
        self.isAnimatingSwap = false
        self.onSwapCompletion?()
      }
    )
  }
}

// MARK: - Rx interface

extension Reactive where Base == TKUIRoutingQueryInputTitleView {
  var originDestination: Binder<(origin: String, destination: String)> {
    return Binder(self.base) { view, od in
      view.setText(origin: od.origin, destination: od.destination)
    }
  }

  var searchMode: Binder<TKUIRoutingResultsViewModel.SearchMode> {
    return Binder(self.base) { view, mode in
      view.fromButton.tintColor = mode == .origin ? .tkAppTintColor : .tkLabelSecondary
      view.toButton.tintColor = mode == .destination ? .tkAppTintColor : .tkLabelSecondary
    }
  }
  
  var enableRoute: Binder<Bool> {
    return Binder(self.base) { view, enabled in
      view.routeButton.isEnabled = enabled
    }
  }
  
  var searchText: Observable<String> {
    base.typed.asObservable()
  }
  
  var selectedSearchMode: Signal<TKUIRoutingResultsViewModel.SearchMode> {
    base.switchMode.asSignal(onErrorSignalWith: .empty())
  }
  
  var route: Signal<Void> {
    return Signal.merge(
      base.routeButton.rx.tap.asSignal(),
      base.route.asSignal(onErrorSignalWith: .empty())
    )
  }
}
