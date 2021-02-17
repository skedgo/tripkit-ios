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

public struct TKUIHomeComponentInput {
  public let homeCardWillAppear: Observable<Bool>
  public let itemSelected: Signal<TKUIHomeComponentItem>
  public let mapRect: Driver<MKMapRect>
}

public struct TKUIHomeComponentContent {
  public init(identity: String, items: [TKUIHomeComponentItem], header: TKUIHomeViewModel.HeaderConfiguration? = nil) {
    self.identity = identity
    self.items = items
    self.header = header
  }
  
  public let identity: String
  public let header: TKUIHomeViewModel.HeaderConfiguration?
  public let items: [TKUIHomeComponentItem]
}

/// This is the `item` that will be used in the context of
/// `RxTableViewSectionedAnimatedDataSource`
public protocol TKUIHomeComponentItem {
  
  /// This is a string that will be used by `RxTableViewSectionedAnimatedDataSource`
  /// to determine if two items are identical when animating cells in and out of a table view.
  var identity: String { get }
  
  /// This will be used by `RxTableViewSectionedAnimatedDataSource` to determine
  /// if an item at a specific index path can be edited.
  var canEdit: Bool { get }
}

extension TKUIHomeComponentItem {
  public var canEdit: Bool { false }
}

/// This protocol defines the requirements for any view models that may display
/// their contents in a `TKUIHomeCard`.
public protocol TKUIHomeComponentViewModel {
  
  /// This builds an instance of a view model whose contents may be displayed
  /// in a `TKUIHomeCard`
  /// - Parameter inputs: The inputs from a `TKUIHomeCard`, which may be used by a component view model
  static func buildInstance(from inputs: TKUIHomeComponentInput) -> Self
  
  /// This closure returns an sequence whose element is a model used to populate
  /// a section of the table view in a `TKUIHomeCard`.
  var homeCardSection: Driver<TKUIHomeComponentContent> { get }
  
  /// This returns an action in response to selecting a row in the section returned by
  /// `homeCardSection`.
  var nextAction: Signal<TKUIHomeCardNextAction> { get }
  
  /// This returns a cell that is used to display a row in the section returned by `homeCardSection`
  /// - Parameters:
  ///   - item: The data model used to construct the cell
  ///   - indexPath: The index path at which the item is located
  ///   - tableView: The table view in which the cell is displayed
  ///
  /// The `section` property of the `indexPath` parameter corresponds to the position of the
  /// component view model in the list of view models passed to a `TKUIHomeViewModel`. As
  /// such, it may change as other component view models are added or removed. It is best not
  /// to use the `section` property when configuring the returned cell.
  func cell(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell?
  
  /// This provides a component view model an opportunity to register the cell class
  /// with the table view in a `TKUIHomeCard`
  /// - Parameter tableView: The table view with which the cell class is registered
  func registerCell(with tableView: UITableView)
  
  /// This gives a component view model an opportunity to specify what actions to display with
  /// a home card component item when the leading edge of the cell corresponding to the item
  /// is swiped
  /// - Parameters:
  ///   - item: The data model representing the cell whose leading edge is swiped
  ///   - indexPath: The index path at which the item is located
  ///   - tableView: The table view in which the item is displayed
  ///
  /// Typical, this method should only return an action configuration if the component view model
  /// is able to handle the incoming `item`.
  ///
  /// - warning: This is only called if your item returns `true` to `canEdit`
  ///
  /// The `section` property of the `indexPath` parameter corresponds to the position of the
  /// component view model in the list of view models passed to a `TKUIHomeViewModel`. As
  /// such, it may change as other component view models are added or removed. It is best not
  /// to use the `section` property when configuring the returned cell.
  func leadingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration?
  
  /// This gives a component view model an opportunity to specify what actions to display with
  /// a home card component item when the trailing edge of the cell corresponding to the item
  /// is swiped.
  /// - Parameters:
  ///   - item: The data model representing the cell whose trailing edge is swiped
  ///   - indexPath: The index path at which the item is located
  ///   - tableView: The table view in which the item is displayed
  ///
  /// Typical, this method should only return an action configuration if the component view model
  /// is able to handle the incoming `item`.
  ///
  /// - warning: This is only called if your item returns `true` to `canEdit`
  ///
  /// The `section` property of the `indexPath` parameter corresponds to the position of the
  /// component view model in the list of view models passed to a `TKUIHomeViewModel`. As
  /// such, it may change as other component view models are added or removed. It is best not
  /// to use the `section` property when configuring the returned cell.
  func trailingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration?
  
  /// This gives a component view model an opportunity to specify what actions to display with
  /// a home card component item when the context menu of the cell corresponding to the item
  /// is triggered.
  /// - Parameters:
  ///   - item: The data model representing the cell whose context menu was triggered
  ///   - indexPath: The index path at which the item is located
  ///   - tableView: The table view in which the item is displayed
  ///
  /// Typical, this method should only return an action configuration if the component view model
  /// is able to handle the incoming `item`.
  ///
  /// The `section` property of the `indexPath` parameter corresponds to the position of the
  /// component view model in the list of view models passed to a `TKUIHomeViewModel`. As
  /// such, it may change as other component view models are added or removed. It is best not
  /// to use the `section` property when configuring the returned cell.
  @available(iOS 13.0, *)
  func contextMenuConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UIContextMenuConfiguration?
}

extension TKUIHomeComponentViewModel {
  
  public func leadingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? { nil }
  
  public func trailingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? { nil }
  
  @available(iOS 13.0, *)
  public func contextMenuConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UIContextMenuConfiguration? { nil }
}

extension TKUIHomeViewModel.Item {
  var componentItem: TKUIHomeComponentItem? {
    switch self {
    case .component(let item): return item
    case .search: return nil
    }
  }
}
