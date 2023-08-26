//
//  TKUIHomeCardCustomizationViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 18/2/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

import TripKit

protocol TKUIHomeCardCustomizationViewControllerDelegate: AnyObject {
  func customizer(_ controller: TKUIHomeCardCustomizationViewController, completed items: [TKUIHomeCard.CustomizedItem])
}

class TKUIHomeCardCustomizationViewController: UITableViewController {
  
  weak var delegate: TKUIHomeCardCustomizationViewControllerDelegate?
  
  private let initialItems: [TKUIHomeCard.CustomizedItem]
  private let disposeBag = DisposeBag()
  
  private let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
  
  private var viewModel: TKUIHomeCardCustomizationViewModel!
  
  init(items: [TKUIHomeCard.CustomizedItem]) {
    self.initialItems = items
    super.init(style: .plain)
    
    navigationItem.title = Loc.CustomizeHome.localizedCapitalized
    navigationItem.rightBarButtonItem = doneItem
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.register(TKUIHomeCustomizerCell.nib, forCellReuseIdentifier: TKUIHomeCustomizerCell.reuseIdentifier)
    
    tableView.setEditing(true, animated: false)
    tableView.allowsSelectionDuringEditing = true
    tableView.separatorInset.left = 48
    tableView.tableFooterView = UIView()

    viewModel = .init(
      items: initialItems,
      selected: tableView.rx.modelSelected(TKUIHomeCardCustomizationViewModel.Item.self).asSignal(),
      moved: tableView.rx.itemMoved.asSignal(),
      done: doneItem.rx.tap.asSignal()
    )
    
    let dataSource = DataSource()
    
    tableView.dataSource = nil // We'll use Rx
    tableView.delegate = nil   // We'll use Rx
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.next
      .emit(onNext: { [weak self] in self?.show($0) })
      .disposed(by: disposeBag)
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
  
  private func show(_ next: TKUIHomeCardCustomizationViewModel.Next) {
    switch next {
    case .done(let items):
      delegate?.customizer(self, completed: items)
    }
  }
  
  override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
    return .none // don't allow deleting; use check box instead
  }
  
}

fileprivate class DataSource: RxTableViewSectionedReloadDataSource<TKUIHomeCardCustomizationViewModel.Section> {
  
  init() {
    super.init(configureCell: Self.cell)
  }

  private static func cell(dataSource: TableViewSectionedDataSource<TKUIHomeCardCustomizationViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUIHomeCardCustomizationViewModel.Item) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: TKUIHomeCustomizerCell.reuseIdentifier, for: indexPath) as! TKUIHomeCustomizerCell

    cell.stateImageView.image = item.isEnabled
      ? UIImage(systemName: "checkmark.circle.fill")
      : UIImage(systemName: "circle")
    
    cell.stateImageView.alpha = item.canBeHidden ? 1 : 0.3
    
    if item.isEnabled {
      cell.accessibilityTraits.insert(.selected)
    } else {
      cell.accessibilityTraits.remove(.selected)
    }

    cell.titleLabel.text = item.title
    
    cell.iconImageView.image = item.icon

    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true // this is needed to get re-order controls
  }
  
  override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return true
  }

}
