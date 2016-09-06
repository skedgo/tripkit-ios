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
    
    self.title = NSLocalizedString("Alerts", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
    
    if let navigator = navigationController,
      let topCtr = navigator.viewControllers.first where topCtr == self {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: nil, action: nil)
      doneButton.rx_tap
        .subscribeNext { self.dismissViewControllerAnimated(true, completion: nil) }
        .addDisposableTo(disposeBag)
      navigationItem.leftBarButtonItem = doneButton
    }
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 150
    tableView.registerNib(TKAlertCell.nib, forCellReuseIdentifier: String(TKAlertCell))
    tableView.separatorStyle = .None
    
    transitAlerts?
      .observeOn(MainScheduler.instance)
      .subscribeNext { [weak self] in
        if let strongSelf = self {
          strongSelf.alerts = $0
        }
      }
      .addDisposableTo(disposeBag)
  }
  
  // MARK: - Table view data source
  
  override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return alerts.count
  }
  
  override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    guard indexPath.row < alerts.count else {
      preconditionFailure("Index path refers to a non-existent alert")
    }
    
    let alertCell = tableView.dequeueReusableCellWithIdentifier(String(TKAlertCell), forIndexPath: indexPath) as! TKAlertCell
    
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
  
  override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
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
    emptyAlertView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
    emptyAlertView.textLabel.text = NSLocalizedString("We'll keep you updated with the latest transit alerts here", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
    
    if let productName = productName() {
      emptyAlertView.footerLabel.text = String(format: NSLocalizedString("In the meantime, let's keep exploring %@ and enjoy your trips", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "%@ is replaced with app name"), productName)
    } else {
      emptyAlertView.footerLabel.text = NSLocalizedString("In the meantime, let's keep exploring and enjoy your trips", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
    }
    
    view.insertSubview(emptyAlertView, aboveSubview: tableView)
    self.emptyAlertView = emptyAlertView
  }
  
  private func productName() -> String? {
    guard
      let infoDict = NSBundle.mainBundle().infoDictionary
      else {
        return nil
    }
    
    return infoDict[kCFBundleNameKey as String] as? String
  }
  
}

// MARK: - Protocol

@objc public protocol TKAlertViewControllerDelegate {
  
  optional func alertViewController(controller: TKAlertViewController, didSelectAlert alert: TKAlert)
  optional func alertViewController(controller: TKAlertViewController, didTapOnURL url: NSURL)
  
}
