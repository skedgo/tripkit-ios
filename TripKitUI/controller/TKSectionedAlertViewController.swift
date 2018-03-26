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
  
  /// This is used to color the labels, as well as to tint the mode
  /// icon in cells.
  ///
  /// @default: `SGStyleManager.darkTextColor`
  public var cellTextColor: UIColor?
  
  private let disposeBag = DisposeBag()
  
  private var dataSource: RxTableViewSectionedReloadDataSource<TKSectionedAlertViewModel.Section>?
  
  public static func newInstance() -> TKSectionedAlertViewController {
    return TKSectionedAlertViewController(nibName: "TKSectionedAlertViewController", bundle: Bundle(for: self))
  }
        
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: "TKRouteCell", bundle: Bundle(for: TKSectionedAlertViewController.self))
    tableView.register(nib, forCellReuseIdentifier: "TKRouteCell")
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 60
    
    bindViewModel()
  }

  override public func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: -
  
  private func bindViewModel() {
    guard viewModel != nil else { assert(false, "No view model found") }
    
    let dataSource = RxTableViewSectionedReloadDataSource<TKSectionedAlertViewModel.Section>(configureCell: { [weak self] (ds, tv, ip, item) -> UITableViewCell in
      let cell = tv.dequeueReusableCell(withIdentifier: "TKRouteCell", for: ip) as! TKRouteCell
      cell.route = item.alertGroup.route
      cell.cellTextColor = self?.cellTextColor
      return cell
    })
    
    self.dataSource = dataSource
    
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
  
  private func didSelect(_ alertItem: TKSectionedAlertViewModel.Item) {
    let controller = TKAlertViewController(style: .plain)
    controller.alerts = alertItem.alerts.map { TKAlertAPIAlertClassWrapper(alert: $0) }
    controller.alertControllerDelegate = self
    navigationController?.pushViewController(controller, animated: true)
  }
  
}

extension TKSectionedAlertViewController {
  
  public override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let source = dataSource else { return nil }
    let header = TKSectionedAlertTableHeader.newInstance()
    let section = source[section]
    header.titleLabel.text = section.header
    header.backgroundColor = section.color
    return header
  }
  
  public override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 44
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
