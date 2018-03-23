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
  
  public var viewModel: TKSectionedAlertViewModel!
  
  private let disposeBag = DisposeBag()
  
  public static func newInstance() -> TKSectionedAlertViewController {
    return TKSectionedAlertViewController(nibName: "TKSectionedAlertViewController", bundle: Bundle(for: self))
  }
        
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: "TKRouteCell", bundle: Bundle(for: TKSectionedAlertViewController.self))
    tableView.register(nib, forCellReuseIdentifier: "TKRouteCell")
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 60
//    tableView.separatorStyle = .none
    
    bindViewModel()
  }

  override public func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: -
  
  private func bindViewModel() {
    guard viewModel != nil else { assert(false, "No view model found") }
    
    let dataSource = RxTableViewSectionedReloadDataSource<AlertSection>(configureCell: { (ds, tv, ip, item) -> UITableViewCell in
      let cell = tv.dequeueReusableCell(withIdentifier: "TKRouteCell", for: ip) as! TKRouteCell
      cell.route = item.alertGroup.route
      cell.alertCount = item.alertGroup.alerts.count
      return cell
    })
    
    // table view section header
    dataSource.titleForHeaderInSection = { ds, index in
      return ds.sectionModels[index].header
    }
    
    viewModel.sections
      .observeOn(MainScheduler.instance)
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    tableView.rx.itemSelected
      .map { dataSource[$0] }
      .subscribe(onNext: { [unowned self] in
        self.didSelect($0)
      })
      .disposed(by: disposeBag)
  }
  
  private func didSelect(_ alertItem: AlertItem) {
    let controller = TKAlertViewController(style: .plain)
    controller.alerts = alertItem.alertGroup.alerts.map { TKAlertAPIAlertClassWrapper(alert: $0) }
    controller.alertControllerDelegate = self
    navigationController?.pushViewController(controller, animated: true)
  }
  
}

extension TKSectionedAlertViewController: TKAlertViewControllerDelegate {
  
  public func alertViewController(_ controller: TKAlertViewController, didTapOnURL url: URL) {
    let browser = SFSafariViewController(url: url)
    present(browser, animated: true, completion: nil)
  }
  
}

extension UIView {
  
  func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    self.layer.mask = mask
  }
  
}
