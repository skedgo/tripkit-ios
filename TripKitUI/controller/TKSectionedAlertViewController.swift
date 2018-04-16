//
//  TKSectionedAlertViewController.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 15/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import SafariServices

public class TKSectionedAlertViewController: UITableViewController {
  
  public var region: SVKRegion!
  public var includeSearchBar: Bool = true
  
  private var viewModel: TKSectionedAlertViewModel!
  
  /// This is the main text color used throughout the view. Examples of
  /// where it is applied: title and subtitle labels in the table view
  /// cells.
  ///
  /// @default: `SGStyleManager.darkTextColor`
  public var textColor: UIColor?
  
  private let disposeBag = DisposeBag()

  private var searchController: UISearchController!
  private let searchText = PublishSubject<String>()
  
  private var dataSource: RxTableViewSectionedReloadDataSource<TKSectionedAlertViewModel.Section>?
  
  // MARK: - Supplementary view
  
  private var emptyAlertView: TKEmptyAlertView?
  private var loadingView: TKLoadingAlertView?
  
  // MARK: - Constructor
  
  public static func newInstance(region: SVKRegion) -> TKSectionedAlertViewController {
    let controller = TKSectionedAlertViewController(nibName: "TKSectionedAlertViewController", bundle: Bundle(for: self))
    controller.region = region
    return controller
  }
  
  // MARK: - View lifecycle
        
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    if #available(iOS 11.0, *), includeSearchBar {
      searchController = UISearchController(searchResultsController: nil)
      searchController.searchResultsUpdater = self
      searchController.obscuresBackgroundDuringPresentation = false
      searchController.searchBar.tintColor = SGStyleManager.globalAccentColor()
      navigationItem.searchController = searchController
      navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    let nib = UINib(nibName: "TKRouteCell", bundle: Bundle(for: TKSectionedAlertViewController.self))
    tableView.register(nib, forCellReuseIdentifier: "TKRouteCell")
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 60
    
    let dataSource = RxTableViewSectionedReloadDataSource<TKSectionedAlertViewModel.Section>(configureCell: { [weak self] (ds, tv, ip, item) -> UITableViewCell in
      let cell = tv.dequeueReusableCell(withIdentifier: "TKRouteCell", for: ip) as! TKRouteCell
      cell.route = item.alertGroup.route
      cell.cellTextColor = self?.textColor
      return cell
    })

    viewModel = TKSectionedAlertViewModel(
      region: region,
      searchText: searchText
    )
    
    self.dataSource = dataSource
    
    viewModel.state
      .map { state -> [TKSectionedAlertViewModel.Section]? in
        switch state {
        case .content(let sections): return sections
        default: return nil
        }
      }
      .filter { $0 != nil}
      .map { $0! }
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.state
      .drive(onNext: { [weak self] state in
        switch state {
        case .loading:
          self?.insertLoadingView()
        case .content(let sections):
          self?.removeLoadingView()
          sections.isEmpty ? self?.insertEmptyAlertView() : self?.removeEmptyAlertView()
        }
      })
      .disposed(by: disposeBag)
    
    tableView.rx.itemSelected
      .map { dataSource[$0] }
      .subscribe(onNext: { [unowned self] in
        self.didSelect($0)
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - User interaction
  
  private func didSelect(_ alertItem: TKSectionedAlertViewModel.Item) {
    let controller = TKAlertViewController(style: .plain)
    controller.alerts = alertItem.alerts.map { TKAlertAPIAlertClassWrapper(alert: $0) }
    controller.alertControllerDelegate = self
    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.pushViewController(controller, animated: true)
  }
  
  // MARK: - Supplementary views
  
  private func insertEmptyAlertView() {
    let emptyView = TKEmptyAlertView.makeView()
    emptyView.frame.size = view.frame.size
    emptyView.autoresizingMask = [.flexibleWidth, .flexibleWidth]
    emptyView.textLabel.text = Loc.WeWillKeepYouUpdated
    emptyView.textLabel.textColor = textColor
    
    if let productName = Bundle.main.productName {
      emptyView.footerLabel.text = Loc.InTheMeantimeKeepExploring(appName: productName)
    }
    
    view.insertSubview(emptyView, aboveSubview: tableView)
    emptyAlertView = emptyView
  }
  
  private func removeEmptyAlertView() {
    emptyAlertView?.removeFromSuperview()
    emptyAlertView = nil
  }
  
  private func insertLoadingView() {
    let loadingView = TKLoadingAlertView.newInstance()
    loadingView.frame.size = view.frame.size
    loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    loadingView.spinner.startAnimating()
    loadingView.textLabel.textColor = textColor
    view.insertSubview(loadingView, aboveSubview: tableView)
    self.loadingView = loadingView
  }
  
  private func removeLoadingView() {
    loadingView?.spinner.stopAnimating()
    loadingView?.removeFromSuperview()
    loadingView = nil
  }
  
}

extension TKSectionedAlertViewController {
  
  public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let source = dataSource else { return nil }
    let header = TKSectionedAlertTableHeader.newInstance()
    let section = source[section]
    header.titleLabel.text = section.header
    header.backgroundColor = section.color
    return header
  }
  
  public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 44
  }
  
}

extension TKSectionedAlertViewController: TKAlertViewControllerDelegate {
  
  public func alertViewController(_ controller: TKAlertViewController, didTapOnURL url: URL) {
    let browser = SFSafariViewController(url: url)
    present(browser, animated: true, completion: nil)
  }
  
}

extension TKSectionedAlertViewController: UISearchControllerDelegate {
}

extension TKSectionedAlertViewController: UISearchResultsUpdating {
  
  public func updateSearchResults(for searchController: UISearchController) {
    searchText.onNext(searchController.searchBar.text ?? "")
  }
  
}
