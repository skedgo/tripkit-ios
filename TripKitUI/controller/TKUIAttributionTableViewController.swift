//
//  TKUIAttributionTableViewController.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 3/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUIAttributionTableViewController: UITableViewController {
  
  /// Called when the user taps on an item in the attribution view, and
  /// requests displaying that URL. You should then either present it in an
  /// in-app web view, or call `UIApplication.shared.open()`.
  ///
  /// - warning: Make sure you provide either this or a delegate
  public static var presentAttributionHandler: ((TKUIAttributionTableViewController, URL) -> Void)?

  public var attributions: [TKAPI.DataAttribution] = []
  
  public convenience init(attributions: [TKAPI.DataAttribution]) {
    self.init(style: .plain)
    
    self.attributions = attributions
    self.title = Loc.DataProviders
  }
  
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.backgroundColor = .tkBackground
    
    navigationItem.leftBarButtonItem = UIBarButtonItem(title: Loc.Close, style: .done, target: self, action: #selector(closeButtonPressed(_:)))

    tableView.register(TKUIAttributionCell.nib, forCellReuseIdentifier: TKUIAttributionCell.reuseIdentifier)

    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 44
    tableView.tableFooterView = UIView()
  }
  
  @objc
  fileprivate func closeButtonPressed(_ sender: Any) {
    presentingViewController?.dismiss(animated: true)
  }
  

  // MARK: - Table view data source

  override public func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return attributions.count
  }

  override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: TKUIAttributionCell.reuseIdentifier, for: indexPath) as! TKUIAttributionCell
    cell.attribution = attributions[indexPath.row]
    return cell
  }
  
  override public func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
    guard let url = attributions[indexPath.row].provider.website else {
      assertionFailure("Shouldn't have accessory button if there's no website")
      return
    }

    Self.presentAttributionHandler?(self, url)
  }
  
}
