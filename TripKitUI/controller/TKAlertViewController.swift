//
//  TKAlertViewController.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

#if TK_NO_MODULE
#else
  import TripKit
#endif

@objc
public protocol TKAlertModel {
  var title: String? { get }
  var icon: SGKImage? { get }
  var iconURL: URL? { get }
  var text: String? { get }
  var infoURL: URL? { get }
  var lastUpdated: Date? { get }
}

public class TKAlertViewController: UITableViewController {
  
  private let disposeBag = DisposeBag()
  private weak var emptyAlertView: TKEmptyAlertView?
  
  private var alerts: [TKAlertModel] = [] {
    didSet {
      if alerts.isEmpty {
        insertEmptyAlertsView()
      } else {
        emptyAlertView?.removeFromSuperview()
        tableView.reloadData()
      }
    }
  }
  
  public var transitAlerts: Observable<[TKAlertModel]>?
  @objc public weak var alertControllerDelegate: TKAlertViewControllerDelegate?
  
  // MARK: - View lifecycle
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = Loc.Alerts
    
    if let navigator = navigationController,
      let topCtr = navigator.viewControllers.first, topCtr == self {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
      doneButton.rx.tap
        .subscribe(onNext: { [unowned self] in
          self.dismiss(animated: true, completion: nil)
        })
        .disposed(by: disposeBag)
      navigationItem.leftBarButtonItem = doneButton
    }
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 150
    tableView.register(TKAlertCell.nib, forCellReuseIdentifier: String(describing: TKAlertCell.self))
    SGStyleManager.styleTableView(forTileList: tableView)
    
    transitAlerts?
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] in
        if let strongSelf = self {
          strongSelf.alerts = $0
        }
      })
      .disposed(by: disposeBag)
  }
  
  // MARK: - UITableViewDataSource
  
  override public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return alerts.count
  }
  
  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < alerts.count else {
      preconditionFailure("Index path refers to a non-existent alert")
    }
    
    let alertCell = tableView.dequeueReusableCell(withIdentifier: String(describing: TKAlertCell.self), for: indexPath) as! TKAlertCell
    
    let alert = alerts[indexPath.row]
    
    // This configures the cell.
    alertCell.alert = alert
    
    // This intercepts the tap on the action button.
    alertCell.tappedOnLink
      .subscribe(onNext: { [unowned self] in
        self.alertControllerDelegate?.alertViewController?(self, didTapOnURL: $0)
      })
      .disposed(by: disposeBag)
    
    return alertCell
  }
  
  // MARK: - Table view delegate
  
  override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < alerts.count else {
      return
    }
    
    let alert = alerts[indexPath.row]
    alertControllerDelegate?.alertViewController?(self, didSelectAlert: alert)
  }
  
  // MARK: - Auxiliary view
  
  private func insertEmptyAlertsView() {
    let emptyAlertView = TKEmptyAlertView.makeView()
    emptyAlertView.frame.size = view.frame.size
    emptyAlertView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    emptyAlertView.textLabel.text = Loc.WeWillKeepYouUpdated
    
    if let productName = Bundle.main.productName {
      emptyAlertView.footerLabel.text = Loc.InTheMeantimeKeepExploring(appName: productName)
    }
    
    view.insertSubview(emptyAlertView, aboveSubview: tableView)
    self.emptyAlertView = emptyAlertView
  }
  
}

// MARK: - Protocol

@objc public protocol TKAlertViewControllerDelegate {
  
  @objc optional func alertViewController(_ controller: TKAlertViewController, didSelectAlert alert: TKAlertModel)
  @objc optional func alertViewController(_ controller: TKAlertViewController, didTapOnURL url: URL)
  
}
