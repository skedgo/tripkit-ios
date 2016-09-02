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
  
  public var segment: TKSegment?
  public var alert: Alert?
  public var delegate: TKAlertViewControllerDelegate?
  public weak var delegate: TKAlertViewControllerDelegate?
  
  private let disposeBag = DisposeBag()
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = NSLocalizedString("Alerts", comment: "")
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 150
    tableView.registerNib(TKAlertCell.nib, forCellReuseIdentifier: String(TKAlertCell))
    SGStyleManager.styleTableViewForTileList(tableView)
    
    if let navigator = navigationController,
       let topCtr = navigator.viewControllers.first where topCtr == self {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: nil, action: nil)
      doneButton.rx_tap
        .subscribeNext { self.dismissViewControllerAnimated(true, completion: nil) }
        .addDisposableTo(disposeBag)
      navigationItem.leftBarButtonItem = doneButton
    }
  }
  
  // MARK: - Table view data source
  
  override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let segment = segment else {
      return 0
    }
    
    return segment.alerts().count
  }
  
  override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    guard let alerts = segment?.alerts() where indexPath.row < alerts.count else {
      preconditionFailure("Either segment has no alerts or index path is pointing to a non-existent alert")
    }
    
    let alert = alerts[indexPath.row]
    let alertCell = tableView.dequeueReusableCellWithIdentifier(String(TKAlertCell), forIndexPath: indexPath) as! TKAlertCell
    
    // This configures the cell.
    alertCell.alert = alert
    
    // This intercepts the tap on the action button.
    alertCell.tappedOnLink
      .subscribeNext { self.delegate?.alertViewController(self, didTapOnURL: $0) }
      .addDisposableTo(disposeBag)
    
    if let selected = self.alert where selected.hashCode == alert.hashCode {
      tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
      performSelector(#selector(deselectSelection), withObject: nil, afterDelay: 1.5)
      self.alert = nil
    }
    
    return alertCell
  }
  
  // MARK: - Table view delegate
  
  override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if let alert = segment?.alerts()[indexPath.row] {
      delegate?.alertViewController(self, didSelectAlert: alert)
    }
  }
  
  // MARK: - 
  
  @objc private func deselectSelection() {
    if let selectedIndexPath = tableView.indexPathForSelectedRow {
      tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
    }
  }
}

@objc public protocol TKAlertViewControllerDelegate {
  
  func alertViewController(controller: TKAlertViewController, didSelectAlert alert: Alert)
  func alertViewController(controller: TKAlertViewController, didTapOnURL url: NSURL)
  
}
