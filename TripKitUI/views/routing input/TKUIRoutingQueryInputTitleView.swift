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
  
  fileprivate let startedEditing = PublishSubject<TKUIRoutingResultsViewModel.SearchMode>()
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
    
    swapButton.addTarget(self, action: #selector(animateSwap), for: .touchUpInside)
    
    closeButton.setTitle(Loc.Cancel, for: .normal)
    closeButton.titleLabel?.font = TKStyleManager.customFont(forTextStyle: .body)
    routeButton.setTitle("Route", for: .normal) // TODO: Localise
    routeButton.titleLabel?.font = TKStyleManager.boldCustomFont(forTextStyle: .body)
    
    fromSearchBar.rx.setDelegate(self).disposed(by: disposeBag)
    toSearchBar.rx.setDelegate(self).disposed(by: disposeBag)
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
    case fromSearchBar: startedEditing.onNext(.origin)
    case toSearchBar: startedEditing.onNext(.destination)
    default: assertionFailure()
    }
    return true
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

      switch mode {
      case .origin:
        view.fromSearchBar.becomeFirstResponder()
        if #available(iOS 13.0, *) {
          view.fromSearchBar.searchTextField.selectedTextRange = view.fromSearchBar.searchTextField.textualRange
        }
      case .destination:
        view.toSearchBar.becomeFirstResponder()
        if #available(iOS 13.0, *) {
          view.toSearchBar.searchTextField.selectedTextRange = view.toSearchBar.searchTextField.textualRange
        }
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
        base.startedEditing.asSignal(onErrorSignalWith: .empty()),
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
