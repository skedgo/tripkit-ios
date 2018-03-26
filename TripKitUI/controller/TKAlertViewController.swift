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

@objc public protocol TKAlert {
  var title: String? { get }
  var icon: SGKImage? { get }
  var iconURL: URL? { get }
  var text: String? { get }
  var infoURL: URL? { get }
  var startTime: Date? { get }
  var lastUpdated: Date? { get }
}

// MARK: -

/// This is a wrapper class that converts an instance of API.Alert into
/// an instance that can conform to object protocol `TKAlert`.
class TKAlertAPIAlertClassWrapper {
  private let alert: API.Alert

  init(alert: API.Alert) {
    self.alert = alert
  }
}

extension TKAlertAPIAlertClassWrapper: TKAlert {
  var title: String? { return alert.title }
  var iconURL: URL? { return alert.remoteIcon }
  var text: String? { return alert.text }
  var infoURL: URL? { return alert.url }
  var lastUpdated: Date? { return alert.lastUpdated }
  var startTime: Date? { return alert.fromDate }
  
  var icon: SGKImage? {
    let fileName: String
    switch alert.severity {
    case .info, .warning:
      fileName = "icon-alert-yellow-high-res"
    case .alert:
      fileName = "icon-alert-red-high-res"
    }    
    return TripKitUIBundle.imageNamed(fileName)
  }
}

// MARK: -

public class TKAlertViewController: UITableViewController {
  
  @objc public weak var alertControllerDelegate: TKAlertViewControllerDelegate?
  
  private weak var emptyAlertView: TKEmptyAlertView?
  
  private let disposeBag = DisposeBag()
  
  public var alerts: [TKAlert] = [] {
    didSet {
      if alerts.isEmpty {
        insertEmptyAlertsView()
      } else {
        emptyAlertView?.removeFromSuperview()
        tableView.reloadData()
      }
    }
  }
  
  // MARK: - View lifecycle
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = Loc.Alerts
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 150
    tableView.register(UINib(nibName: "TKAlertCell", bundle: Bundle(for: TKAlertCell.self)), forCellReuseIdentifier: "TKAlertCell")
    SGStyleManager.styleTableView(forTileList: tableView)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let navigator = navigationController,
      let firstCOntroller = navigator.viewControllers.first, firstCOntroller == self {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(_:)))
      navigationItem.leftBarButtonItem = doneButton
    }
  }
  
  @objc private func doneButtonTapped(_ sender: UIButton) {
    dismiss(animated: true, completion: nil)
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
    
    let alertCell = tableView.dequeueReusableCell(withIdentifier: "TKAlertCell", for: indexPath) as! TKAlertCell
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
  
  @objc optional func alertViewController(_ controller: TKAlertViewController, didSelectAlert alert: TKAlert)
  @objc optional func alertViewController(_ controller: TKAlertViewController, didTapOnURL url: URL)
  
}
