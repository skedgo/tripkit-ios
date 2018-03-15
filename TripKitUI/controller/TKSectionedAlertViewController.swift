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

public class TKSectionedAlertViewController: UITableViewController {
  
  public var viewModel: TKSectionedAlertViewModel!
  
  private let disposeBag = DisposeBag()
  
  public static func newInstance() -> TKSectionedAlertViewController {
    return TKSectionedAlertViewController(nibName: "TKSectionedAlertViewController", bundle: Bundle(for: self))
  }
        
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    bindViewModel()
  }

  override public func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: -
  
  private func bindViewModel() {
    guard viewModel != nil else { assert(false, "No view model found") }
    
    let dataSource = RxTableViewSectionedReloadDataSource<AlertSection>(configureCell: { [weak self] (ds, tv, ip, item) -> UITableViewCell in
      var cell = tv.dequeueReusableCell(withIdentifier: "StandardCell")
      if cell == nil {
        cell = UITableViewCell(style: .default, reuseIdentifier: "StandardCell")
      }
      cell!.textLabel?.text = item.name
      return cell!
    })
    
    viewModel.sections
      .observeOn(MainScheduler.instance)
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
  }
}
