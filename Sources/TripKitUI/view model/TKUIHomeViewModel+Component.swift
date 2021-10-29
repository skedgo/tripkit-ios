//
//  TKUIHomeViewModel+Component.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 31/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import RxSwift
import RxCocoa

public struct TKUIHomeHeaderConfiguration {
  public let title: String
  public var action: (title: String, handler: () -> TKUIHomeCard.ComponentAction)?
  
  public init(title: String, action: (String, () -> TKUIHomeCard.ComponentAction)? = nil) {
    self.title = title
    self.action = action
  }
}


public struct TKUIHomeComponentInput {
  public let homeCardWillAppear: Observable<Bool>
  public let itemSelected: Signal<TKUIHomeComponentItem>
  public let mapRect: Driver<MKMapRect>
}

public struct TKUIHomeComponentContent {
  public init(items: [TKUIHomeComponentItem]?, header: TKUIHomeHeaderConfiguration? = nil) {
    self.items = items
    self.header = header
  }
  
  public let header: TKUIHomeHeaderConfiguration?
  public let items: [TKUIHomeComponentItem]?
}

/// This is the `item` that will be used in the context of
/// `RxTableViewSectionedAnimatedDataSource`
public protocol TKUIHomeComponentItem {
  
  /// This is a string that will be used by `RxTableViewSectionedAnimatedDataSource`
  /// to determine if two items are identical when animating cells in and out of a table view.
  var identity: String { get }
  
  /// Pseudo-equality, used to determine if an item has changed. Defaults to just `identity`.
  var equalityToken: String { get }
  
  /// This will be used by `RxTableViewSectionedAnimatedDataSource` to determine
  /// if an item at a specific index path can be edited. Defaults to `false`.
  var canEdit: Bool { get }
  
  /// This indicates it the item triggers an action. It can be used to determine if an UI element,
  /// such as a row in a table view should be treated as a button when supporting accessibility.
  /// Defaults to `true`.
  var isAction: Bool { get }
  
}

extension TKUIHomeComponentItem {
  public var canEdit: Bool { false }
  public var equalityToken: String { identity }
  public var isAction: Bool { true }
}

/// The representation of an home card component for the customizer
public struct TKUIHomeCardCustomizerItem {
  public init(name: String, icon: UIImage, canBeHidden: Bool = true) {
    self.name = name
    self.icon = icon
    self.canBeHidden = canBeHidden
  }
  
  /// User-friendly name of this section.
  public let name: String

  /// Icon for this section.
  public let icon: UIImage

  /// Whether the user should should be allowed to hide this in the customizer. Defaults to `true`.
  public var canBeHidden: Bool = true
}

/// This protocol defines the requirements for any view models that may display
/// their contents in a `TKUIHomeCard`.
public protocol TKUIHomeComponentViewModel {

  /// This builds an instance of a view model whose contents may be displayed
  /// in a `TKUIHomeCard`
  /// - Parameter inputs: The inputs from a `TKUIHomeCard`, which may be used by a component view model
  static func buildInstance(from inputs: TKUIHomeComponentInput) -> Self

  /// A unique identifier for this component
  var identity: String { get }
  
  /// How this component should appear in the card customizer
  ///
  /// Return `nil` if it should not be included in the customizer
  var customizerItem: TKUIHomeCardCustomizerItem? { get }
  
  /// This closure returns an sequence whose element is a model used to populate
  /// a section of the table view in a `TKUIHomeCard`.
  ///
  /// You can hide a section dynamically by using `items == nil`. A section with empty
  /// items will still show just its header.
  var homeCardSection: Driver<TKUIHomeComponentContent> { get }
  
  /// This returns an action in response to selecting a row in the section returned by
  /// `homeCardSection`.
  var nextAction: Signal<TKUIHomeCard.ComponentAction> { get }
  
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
  func contextMenuConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UIContextMenuConfiguration?
}

extension TKUIHomeComponentViewModel {
  
  public var nextAction: Signal<TKUIHomeCard.ComponentAction> { .empty() }
  
  public func leadingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? { nil }
  
  public func trailingSwipeActionsConfiguration(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UISwipeActionsConfiguration? { nil }
  
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
