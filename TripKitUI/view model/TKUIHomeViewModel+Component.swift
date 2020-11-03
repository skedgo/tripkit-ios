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
  public let itemDeleted: Signal<TKUIHomeComponentItem>
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
  
  func leadingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration?
  
  func trailingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration?
  
}

extension TKUIHomeComponentViewModel {
  
  public func leadingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? { return nil }
  
  public func trailingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? { return nil }
  
}

extension TKUIHomeViewModel.Item {
  var componentItem: TKUIHomeComponentItem? {
    switch self {
    case .component(let item): return item
    case .search: return nil
    }
  }
}
