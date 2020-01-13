//
//  TKUIAlertViewController.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 31/08/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit
import SafariServices

import RxSwift

#if TK_NO_MODULE
#else
  import TripKit
#endif

@objc public protocol TKAlert {
  var title: String? { get }
  var icon: TKImage? { get }
  var iconURL: URL? { get }
  var text: String? { get }
  var infoURL: URL? { get }
  var startTime: Date? { get }
  var lastUpdated: Date? { get }
  
  func isCritical() -> Bool
}


// MARK: -

/// This is a wrapper class that converts an instance of API.Alert into
/// an instance that can conform to object protocol `TKAlert`.
class TKAlertAPIAlertClassWrapper {
  private let alert: TKAPI.Alert

  init(alert: TKAPI.Alert) {
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
  
  var icon: TKImage? {
    let fileName: String
    switch alert.severity {
    case .info, .warning:
      fileName = "icon-alert-yellow-high-res"
    case .alert:
      fileName = "icon-alert-red-high-res"
    }    
    return TripKitUIBundle.imageNamed(fileName)
  }
  
  func isCritical() -> Bool {
    switch alert.severity {
    case .alert: return true
    default: return false
    }
  }
}

// MARK: -

@available(*, unavailable, renamed: "TKUIAlertViewController")
public typealias TKAlertViewController = TKUIAlertViewController

public class TKUIAlertViewController: UITableViewController {
  
  @objc public weak var alertControllerDelegate: TKUIAlertViewControllerDelegate?
  
  private weak var emptyAlertView: TKUIEmptyAlertView?
  
  private let disposeBag = DisposeBag()
  
  public func setAlerts(_ alerts: [TKAPI.Alert]) {
    self.alerts = alerts.map(TKAlertAPIAlertClassWrapper.init)
  }
  
  public var alerts: [TKAlert] = [] {
    didSet {
      sortedAlerts = alerts
        .sorted(by: {
          switch ($0.startTime, $1.startTime) {
          case (.some(let date1), .some(let date2)): return date1 > date2
          case (.some, nil): return true
          default: return false
          }
        })
        .sorted(by: { $0.isCritical() && !$1.isCritical() })
    }
  }
  
  private var sortedAlerts: [TKAlert] = [] {
    didSet {
      if sortedAlerts.isEmpty {
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
    
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 150
    tableView.register(UINib(nibName: "TKUIAlertCell", bundle: Bundle(for: TKUIAlertCell.self)), forCellReuseIdentifier: "TKUIAlertCell")
    tableView.backgroundColor = .tkBackgroundGrouped
    tableView.separatorStyle = .none
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if let navigator = navigationController,
      let firstController = navigator.viewControllers.first, firstController == self {
      let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped(_:)))
      navigationItem.leftBarButtonItem = doneButton
    }
  }
  
  @objc private func doneButtonTapped(_ sender: UIButton) {
    dismiss(animated: true)
  }
  
  // MARK: - UITableViewDataSource
  
  override public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sortedAlerts.count
  }
  
  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard indexPath.row < sortedAlerts.count else {
      preconditionFailure("Index path refers to a non-existent alert")
    }
    
    let alertCell = tableView.dequeueReusableCell(withIdentifier: "TKUIAlertCell", for: indexPath) as! TKUIAlertCell
    let alert = sortedAlerts[indexPath.row]
    
    // This configures the cell.
    alertCell.alert = alert
    
    // This intercepts the tap on the action button.
    alertCell.tappedOnLink
      .subscribe(onNext: { [unowned self] in
        let browser = SFSafariViewController(url: $0)
        self.present(browser, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)
    
    return alertCell
  }
  
  // MARK: - Table view delegate
  
  override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < sortedAlerts.count else {
      return
    }
    
    let alert = sortedAlerts[indexPath.row]
    alertControllerDelegate?.alertViewController?(self, didSelectAlert: alert)
  }
  
  // MARK: - Auxiliary view
  
  private func insertEmptyAlertsView() {
    let emptyAlertView = TKUIEmptyAlertView.makeView()
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

@objc public protocol TKUIAlertViewControllerDelegate {
  
  @objc optional func alertViewController(_ controller: TKUIAlertViewController, didSelectAlert alert: TKAlert)
  
}
