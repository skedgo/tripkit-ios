//
//  TKUILocationSearchViewController.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 4/10/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

enum TKUILocationSearchSpecifier {
  case origin
  case destination
}

protocol TKUILocationSearchViewControllerDelegate {
  
  func locationSearchController(_ controller: TKUILocationSearchViewController, selected annotation: MKAnnotation, for specifier: TKUILocationSearchSpecifier)
  
}

class TKUILocationSearchViewController: UITableViewController {
  
  var searchController: UISearchController!
  
  var delegate: TKUILocationSearchViewControllerDelegate?
  
  let searchSpecifier: TKUILocationSearchSpecifier
  
  var autocompletionDataProviders: [TKAutocompleting]?
  
  init(for searchSpecifier: TKUILocationSearchSpecifier) {
    self.searchSpecifier = searchSpecifier
    super.init(style: .plain)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let resultsController = configureResultsController()
    
    let searchController = UISearchController(searchResultsController: resultsController)
    searchController.searchResultsUpdater = resultsController
    searchController.searchBar.placeholder = (searchSpecifier == .origin) ? "Search origin" : "Search destination"
    searchController.searchBar.delegate = self
    
    TKStyleManager.style(searchController.searchBar, includingBackground: false) {
      $0.backgroundColor = .tkBackground
      $0.tintColor = .tkLabelPrimary
      $0.textColor = .tkLabelPrimary
    }
    
    tableView.tableHeaderView = searchController.searchBar
    
    self.searchController = searchController
  }
  
  private func configureResultsController() -> TKUIAutocompletionViewController {
    let resultsController: TKUIAutocompletionViewController
    
    if let providers = autocompletionDataProviders {
      resultsController = TKUIAutocompletionViewController(providers: providers)
    } else {
      let geocoders: [AnyObject] = [TKAppleGeocoder(), TKSkedGoGeocoder()]
      let providers = geocoders.compactMap { $0 as? TKAutocompleting }
      resultsController = TKUIAutocompletionViewController(providers: providers)
    }
    
    if #available(iOS 11, *) {
      resultsController.tableView.contentInsetAdjustmentBehavior = .never
    }
    
    resultsController.delegate = self
    
    return resultsController
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    searchController.isActive = true
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    return 0
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 0
  }

  /*
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

      // Configure the cell...

      return cell
  }
  */

}

extension TKUILocationSearchViewController: UISearchBarDelegate {
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    dismiss(animated: true, completion: nil)
  }
  
}

extension TKUILocationSearchViewController: TKUIAutocompletionViewControllerDelegate {
  
  func autocompleter(_ controller: TKUIAutocompletionViewController, didSelect annotation: MKAnnotation) {
    delegate?.locationSearchController(self, selected: annotation, for: searchSpecifier)
  }
  
  func autocompleter(_ controller: TKUIAutocompletionViewController, didSelectAccessoryFor annotation: MKAnnotation) {
    //
  }
  
}
