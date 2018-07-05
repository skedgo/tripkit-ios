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
}


/// Displays autocompletion results from search
///
/// Typically used as a `searchResultsController` being passed
/// to a `UISearchController` and assigned to that search
/// controller's `searchResultsUpdater` property.
public class TKUIAutocompletionViewController: UITableViewController {

  public let providers: [TKAutocompleting]
  
  public weak var delegate: TKUIAutocompletionViewControllerDelegate?
  
  public var biasMapRect: MKMapRect = MKMapRectNull

  private var viewModel: TKUIAutocompletionViewModel!
  private let disposeBag = DisposeBag()
  
  private let searchText = PublishSubject<String>()

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
      configureCell: { _, _, _, item in
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.imageView?.image = item.image
        cell.imageView?.tintColor = #colorLiteral(red: 0.8500000238, green: 0.8500000238, blue: 0.8500000238, alpha: 1) // From SkedGo default icons
        cell.textLabel?.text = item.title
        cell.textLabel?.textColor = SGStyleManager.darkTextColor()
        cell.detailTextLabel?.text = item.subtitle
        cell.detailTextLabel?.textColor = SGStyleManager.lightTextColor()
        cell.contentView.alpha = item.showFaded ? 0.33 : 1
        
        if let accessoryImage = item.accessoryImage {
          cell.accessoryView = SGStyleManager.cellAccessoryButton(with: accessoryImage, target: nil, action: nil)
        } else {
          cell.accessoryView = nil
        }
        
        return cell
      }
    )
    
    viewModel = TKUIAutocompletionViewModel(
      providers: providers,
      searchText: searchText,
      selected: tableView.rx.itemSelected.map { dataSource[$0] },
      biasMapRect: biasMapRect
    )
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.selection
      .drive(onNext: { [weak self] result in
        guard let `self` = self else { return }
        self.delegate?.autocompleter(self, didSelect: result)
      })
      .disposed(by: disposeBag)
  }
}

extension TKUIAutocompletionViewController: UISearchResultsUpdating {
  
  public func updateSearchResults(for searchController: UISearchController) {
    searchText.onNext(searchController.searchBar.text ?? "")
  }
  
}
