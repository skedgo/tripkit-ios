//
//  TKUIRoutingQueryInputTitleView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 23.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

class TKUIRoutingQueryInputTitleView: UIView {
  
  static func newInstance() -> TKUIRoutingQueryInputTitleView {
    return Bundle.tripKitUI.loadNibNamed("TKUIRoutingQueryInputTitleView", owner: self, options: nil)?.first as! TKUIRoutingQueryInputTitleView
  }
  
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var routeButton: UIButton!
  
  @IBOutlet weak var fromSearchBar: UISearchBar!
  @IBOutlet weak var toSearchBar: UISearchBar!
  @IBOutlet weak var fromButton: UIButton!
  @IBOutlet weak var toButton: UIButton!
  @IBOutlet weak var swapButton: UIButton!

  @IBOutlet weak var buttonLine: UIView!
  
  // This is a hack to only start switching first responder when the view
  // did appear.
  var didAppear: Bool = false
  
  private var isAnimatingSwap: Bool = false
  private var onSwapCompletion: (() -> Void)? = nil
  
  fileprivate let switchMode = PublishSubject<TKUIRoutingResultsViewModel.SearchMode>()
  fileprivate let typed = PublishSubject<String>()
  fileprivate let route = PublishSubject<Void>()
  
  private let disposeBag = DisposeBag()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    titleLabel.text = Loc.ChangeRoute
    
    func style(_ searchBar: UISearchBar, label: String) {
      searchBar.backgroundImage = UIImage() // blank
      
      // Don't show search icon, i.e., the magnifying glass
      searchBar.setImage(nil, for: .search, state: .normal)
      
      // This is to remove the space occupied by the magnifying glass.
      let textField = searchBar.searchTextField
      textField.accessibilityLabel = label
      textField.leftView = UIImageView()
      textField.tintColor = .tkLabelPrimary
      textField.textColor = .tkLabelPrimary
    }
    
    style(fromSearchBar, label: Loc.StartLocation)
    style(toSearchBar, label: Loc.EndLocation)
    fromSearchBar.placeholder = Loc.StartLocation
    fromSearchBar.enablesReturnKeyAutomatically = true
    toSearchBar.placeholder = Loc.EndLocation
    toSearchBar.enablesReturnKeyAutomatically = true
    
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
      .subscribe(onNext: { [weak self] _ in self?.switchMode(to: .origin, updateResponder: true) })
      .disposed(by: disposeBag)

    toButton.rx.tap
      .subscribe(onNext: { [weak self] _ in self?.switchMode(to: .destination, updateResponder: true) })
      .disposed(by: disposeBag)
    
    fromSearchBar.delegate = self
    toSearchBar.delegate = self
    
    accessibilityElements = [
      closeButton, titleLabel, routeButton, fromSearchBar, swapButton, toSearchBar
    ].compactMap { $0 }
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
  
  private func switchMode(to mode: TKUIRoutingResultsViewModel.SearchMode, updateResponder: Bool) {
    /// Tell the VM (the confirmation of that will be that it'll update the dot colours
    switchMode.onNext(mode)

    if updateResponder {
      becomeFirstResponder(mode: mode)
    }
  }
  
  func becomeFirstResponder(mode: TKUIRoutingResultsViewModel.SearchMode?) {
    if let mode = mode {
      focusOn(mode: mode)
    } else {
      routeButton.becomeFirstResponder()
      UIAccessibility.post(notification: .layoutChanged, argument: routeButton)
    }
  }
  
  private func focusOn(mode: TKUIRoutingResultsViewModel.SearchMode) {
    guard
      let searchBar = mode == .origin ? fromSearchBar : toSearchBar,
      !searchBar.isFirstResponder
      else { return }
    
    searchBar.becomeFirstResponder()
    searchBar.searchTextField.selectedTextRange = searchBar.searchTextField.textualRange
    
    // A bit of a hacky way to make sure that VoiceOver follows the first
    // responder, which is preferred behaviour as otherwise it might stay
    // on the owner's list of locations (which likely just changed, too).
    // See https://redmine.buzzhives.com/issues/16010
    UIAccessibility.post(notification: .layoutChanged, argument: searchBar)
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
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    switch searchBar {
    case fromSearchBar: switchMode(to: .origin, updateResponder: false)
    case toSearchBar: switchMode(to: .destination, updateResponder: false)
    default: assertionFailure()
    }
    
    // Before editing begins, we publish the current search text so that
    // the autocompletion shows immediate results if available.
    typed.onNext(searchBar.text ?? "")
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    // We are publishing the search mode here again because it's possible that
    // the text change was initiated from a search bar that does not match the
    // current search mode, see: https://redmine.buzzhives.com/issues/12017.
    switch searchBar {
    case fromSearchBar: switchMode(to: .origin, updateResponder: false)
    case toSearchBar: switchMode(to: .destination, updateResponder: false)
    default: assertionFailure()
    }
    
    typed.onNext(searchText)
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    self.route.onNext(())
    searchBar.resignFirstResponder()
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

  var searchMode: Binder<TKUIRoutingResultsViewModel.SearchMode?> {
    return Binder(self.base) { view, mode in
      if let mode = mode {
        view.fromButton.tintColor = mode == .origin ? .tkAppTintColor : .tkLabelSecondary
        view.toButton.tintColor = mode == .destination ? .tkAppTintColor : .tkLabelSecondary
      }

      if view.didAppear {
        view.becomeFirstResponder(mode: mode)
      }
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
