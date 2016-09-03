//
//  TKAlertViewController.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import TripKit
import SGCoreKit
import RxSwift

public class TKAlertViewController: UITableViewController {
  
  private let disposeBag = DisposeBag()
  private weak var emptyAlertView: TKEmptyAlertView?
  
  private var alerts: [TKAlert] = [] {
    didSet {
      if alerts.isEmpty {
        insertEmptyAlertsView()
      } else {
        emptyAlertView?.removeFromSuperview()
        tableView.reloadData()
      }
    }
  }
  
  public var transitAlerts: Observable<[TKAlert]>?
  public weak var alertControllerDelegate: TKAlertViewControllerDelegate?
  
  // MARK: - View lifecycle
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = NSLocalizedString("Alerts", comment: "")
    
    if let navigator = navigationController,
      let topCtr = navigator.viewControllers.first , topCtr == self {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
      doneButton.rx.tap
        .subscribeNext { self.dismiss(animated: true, completion: nil) }
        .addDisposableTo(disposeBag)
      navigationItem.leftBarButtonItem = doneButton
    }
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 150
    tableView.register(TKAlertCell.nib, forCellReuseIdentifier: String(describing: TKAlertCell.self))
    tableView.separatorStyle = .none
    
    transitAlerts?
      .subscribeNext { [weak self] in
        if let strongSelf = self {
          strongSelf.alerts = $0
        }
      }
      .addDisposableTo(disposeBag)
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
      .subscribeNext { self.alertControllerDelegate?.alertViewController?(self, didTapOnURL: $0) }
      .addDisposableTo(disposeBag)
    
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
    emptyAlertView.textLabel.text = NSLocalizedString("We'd keep you updated with the latest transit alerts here", comment: "")
    
    if let productName = productName() {
      emptyAlertView.footerLabel.text = String(format: NSLocalizedString("In the meantime, let's keep exploring %@ and enjoy your trips", comment: "%@ is replaced with app name"), productName)
    } else {
      emptyAlertView.footerLabel.text = NSLocalizedString("In the meantime, let's keep exploring and enjoy your trips", comment: "")
    }
    
    view.insertSubview(emptyAlertView, aboveSubview: tableView)
    self.emptyAlertView = emptyAlertView
  }
  
  private func productName() -> String? {
    guard
      let infoDict = Bundle.main.infoDictionary,
      let bundleNameKey = kCFBundleNameKey as? String
      else {
        return nil
    }
    
    return infoDict[bundleNameKey] as? String
  }
  
}

// MARK: - Protocol

@objc public protocol TKAlertViewControllerDelegate {
  
  @objc optional func alertViewController(_ controller: TKAlertViewController, didSelectAlert alert: TKAlert)
  @objc optional func alertViewController(_ controller: TKAlertViewController, didTapOnURL url: URL)
  
}
