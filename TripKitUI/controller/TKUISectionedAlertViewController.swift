//
//  TKUISectionedAlertViewController.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 15/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import SafariServices

@available(*, unavailable, renamed: "TKUISectionedAlertViewController")
public typealias TKSectionedAlertViewController = TKUISectionedAlertViewController

public class TKUISectionedAlertViewController: UIViewController {
  
  private(set) var region: TKRegion!
  public var eventTrackingDelegate: TKUIEventTrackable?
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!
  
  private var viewModel: TKUISectionedAlertViewModel!
  
  private let disposeBag = DisposeBag()
  private let searchText = PublishSubject<String>()
  
  private var dataSource: RxTableViewSectionedReloadDataSource<TKUISectionedAlertViewModel.Section>?
  
  // MARK: - Supplementary view
  
  private var emptyAlertView: TKUIEmptyAlertView?
  private var loadingView: TKUILoadingAlertView?
  
  // MARK: - Constructor
  
  public static func newInstance(region: TKRegion) -> TKUISectionedAlertViewController {
    let controller = TKUISectionedAlertViewController(nibName: "TKUISectionedAlertViewController", bundle: Bundle(for: self))
    controller.region = region
    return controller
  }
  
  // MARK: - View lifecycle
        
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = TKStyleManager.globalViewBackgroundColor()
    
    customizeSearchBar()
    
    tableView.register(TKUIGroupedAlertCell.nib, forCellReuseIdentifier: TKUIGroupedAlertCell.cellReuseIdentifier)
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 60
    tableView.sectionHeaderHeight = UITableView.automaticDimension
    tableView.estimatedSectionHeaderHeight = 44
    
    let dataSource = RxTableViewSectionedReloadDataSource<TKUISectionedAlertViewModel.Section>(
      configureCell: {(ds, tv, ip, item) -> UITableViewCell in
        let cell = tv.dequeueReusableCell(withIdentifier: TKUIGroupedAlertCell.cellReuseIdentifier, for: ip) as! TKUIGroupedAlertCell
        cell.alertGroup = item.alertGroup
        cell.cellTextColor = .tkLabelPrimary
        return cell
      }
    )

    viewModel = TKUISectionedAlertViewModel(
      region: region,
      searchText: searchText
    )
    
    self.dataSource = dataSource
    
    viewModel.state
      .map { state -> [TKUISectionedAlertViewModel.Section]? in
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
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    eventTrackingDelegate?.trackScreen(named: "ServiceDisruptions")
  }
  
  // MARK: - User interaction
  
  private func didSelect(_ alertItem: TKUISectionedAlertViewModel.Item) {
    let controller = TKUIAlertViewController(style: .plain)
    controller.alerts = alertItem.alerts.map { TKAlertAPIAlertClassWrapper(alert: $0) }
    controller.alertControllerDelegate = self
    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.pushViewController(controller, animated: true)
  }
  
  // MARK: - Supplementary views
  
  private func insertEmptyAlertView() {
    // Remove the old one, just to be safe.
    emptyAlertView?.removeFromSuperview()
    
    // Create the new one
    let emptyView = TKUIEmptyAlertView.makeView()
    emptyView.frame = tableView.frame
    emptyView.autoresizingMask = [.flexibleWidth, .flexibleWidth]
    emptyView.textLabel.text = Loc.WeWillKeepYouUpdated
    emptyView.textLabel.textColor = .tkLabelPrimary
    
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
    let loadingView = TKUILoadingAlertView.newInstance()
    loadingView.frame = tableView.frame
    loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    loadingView.spinner.startAnimating()
    loadingView.textLabel.textColor = .tkLabelPrimary
    view.insertSubview(loadingView, aboveSubview: tableView)
    self.loadingView = loadingView
  }
  
  private func removeLoadingView() {
    loadingView?.spinner.stopAnimating()
    loadingView?.removeFromSuperview()
    loadingView = nil
  }
  
  private func customizeSearchBar() {
    TKStyleManager.style(searchBar, includingBackground: false) { textField in
      textField.tintColor = TKStyleManager.globalTintColor()
      textField.textColor = .tkLabelPrimary
      textField.backgroundColor = .white
    }
    searchBar.backgroundColor = TKStyleManager.globalSecondaryBarTintColor()
  }
  
}

// MARK: -
extension TKUISectionedAlertViewController: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let source = dataSource else { return nil }
    let header = TKUISectionedAlertTableHeader.newInstance()
    let section = source[section]
    header.backgroundColor = section.color ?? TKStyleManager.backgroundColorForTileList()
    header.titleLabel.text = section.header
    header.titleLabel.textColor = section.color != nil ? .tkBackground : .tkLabelPrimary
    return header
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // As soon as user starts to scroll, dismiss keyboard.
    searchBar.resignFirstResponder()
  }
  
}

// MARK: -
extension TKUISectionedAlertViewController: TKUIAlertViewControllerDelegate {
  
  public func alertViewController(_ controller: TKUIAlertViewController, didTapOnURL url: URL) {
    let browser = SFSafariViewController(url: url)
    present(browser, animated: true)
  }
  
}

// MARK: - Search bar delegate
extension TKUISectionedAlertViewController: UISearchBarDelegate {
  
  public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.setShowsCancelButton(true, animated: true)
  }
  
  public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.setShowsCancelButton(false, animated: true)
  }
  
  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }
  
  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    searchBar.text = nil
    searchText.onNext("")
    searchBar.resignFirstResponder()
  }
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    self.searchText.onNext(searchText)
  }
  
}
