//
//  TKUIAutocompletionViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 05.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import MapKit

import RxCocoa
import RxSwift
import RxDataSources


public protocol TKUIAutocompletionViewControllerDelegate: class {
  func autocompleter(_ controller: TKUIAutocompletionViewController, didSelect annotation: MKAnnotation)

  func autocompleter(_ controller: TKUIAutocompletionViewController, didSelectAccessoryFor annotation: MKAnnotation)
}


/// Displays autocompletion results from search
///
/// Typically used as a `searchResultsController` being passed
/// to a `UISearchController` and assigned to that search
/// controller's `searchResultsUpdater` property.
public class TKUIAutocompletionViewController: UITableViewController {

  public let providers: [TKAutocompleting]
  
  public weak var delegate: TKUIAutocompletionViewControllerDelegate?
  
  public var showAccessoryButtons = true
  
  public var biasMapRect: MKMapRect = .null

  private var viewModel: TKUIAutocompletionViewModel!
  private let disposeBag = DisposeBag()
  
  private let searchText = PublishSubject<String>()
  private let accessoryTapped = PublishSubject<TKUIAutocompletionViewModel.Item>()

  public init(providers: [TKAutocompleting]) {
    self.providers = providers
    super.init(style: .plain)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIAutocompletionViewModel.Section>(
      configureCell: { [weak self] _, tv, ip, item in
        guard let self = self else {
          // Shouldn't but can happen on dealloc
          return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        guard let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell else {
          preconditionFailure("Couldn't dequeue TKUIAutocompletionResultCell")
        }
        cell.configure(with: item, onAccessoryTapped: self.showAccessoryButtons ? self.accessoryTapped : nil)
        return cell
      },
      titleForHeaderInSection: { ds, index in
        return ds.sectionModels[index].title
      }
    )
    
    // Reset to `nil` as we'll overwrite these
    tableView.delegate = nil
    tableView.dataSource = nil
    
    tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    
    viewModel = TKUIAutocompletionViewModel(
      providers: providers,
      searchText: searchText,
      selected: tableView.rx.itemSelected.map { dataSource[$0] }.asSignal(onErrorSignalWith: .empty()),
      accessorySelected: accessoryTapped.asSignal(onErrorSignalWith: .empty()),
      biasMapRect: biasMapRect
    )
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.selection
      .emit(onNext: { [weak self] annotation in
        guard let self = self else { return }
        self.delegate?.autocompleter(self, didSelect: annotation)
      })
      .disposed(by: disposeBag)

    viewModel.accessorySelection
      .emit(onNext: { [weak self] annotation in
        guard let self = self else { return }
        self.delegate?.autocompleter(self, didSelectAccessoryFor: annotation)
      })
      .disposed(by: disposeBag)
    
    viewModel.triggerAction
      .asObservable()
      .flatMapLatest { $0.triggerAdditional(presenter: self).asObservable() }
      .subscribe()
      .disposed(by: disposeBag)
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
}

extension TKUIAutocompletionViewController {
  
  public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y > 40, !scrollView.isDecelerating {
      // we are actively scrolling a fair bit => disable the keyboard
      (parent as? UISearchController)?.searchBar.resignFirstResponder()
    }
  }
  
}

extension TKUIAutocompletionViewController: UISearchResultsUpdating {
  
  public func updateSearchResults(for searchController: UISearchController) {
    searchText.onNext(searchController.searchBar.text ?? "")
  }
  
}
