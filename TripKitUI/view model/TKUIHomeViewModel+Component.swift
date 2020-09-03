//
//  TKUIHomeViewModel+Component.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

/// This protocol defines the requirements for any view models that may display
/// their contents in a `TKUIHomeCard`.
public protocol TKUIHomeComponentViewModel {
  
  /// This builds an instance of a view model whose contents may be displayed
  /// in a `TKUIHomeCard`
  /// - Parameter inputs: The inputs from a `TKUIHomeCard`, which may be used by a component view model
  static func buildInstance(from inputs: TKUIHomeCard.ComponentViewModelInput) -> Self
  
  /// This closure returns an observable sequence whose element is a model used to populate
  /// a section of the table view in a `TKUIHomeCard`. The closure input is an observable indicating
  /// whether the search is in progress. A component view model may use this to filter contents.
  var homeCardSections: (Observable<Bool>) -> Observable<TKUIHomeViewModel.Section?> { get }
  
  /// This returns an action in response to selecting a row in the section returned by
  /// `homeCardSections`.
  var nextAction: Signal<TKUIHomeCardNextAction> { get }
  
  /// This returns a cell that is used to display a row in the section returned by `homeCardSections`
  /// - Parameters:
  ///   - item: The data model used to construct the cell
  ///   - indexPath: The index path at which the item is located
  ///   - tableView: The table view in which the cell is displayed
  ///
  /// The `section` property of the `indexPath` parameter corresponds to the position of the
  /// component view model in the list of view models passed to a `TKUIHomeViewModel`. As
  /// such, it may change as other component view models are added or removed. It is best not
  /// to use the `section` property when configuring the returned cell.
  func cell(for item: TKUIHomeViewModel.Item, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell?
  
  /// This provides a component view model an opportunity to register the cell class
  /// with the table view in a `TKUIHomeCard`
  /// - Parameter tableView: The table view with which the cell class is registered
  func registerCell(with tableView: UITableView)
  
}

