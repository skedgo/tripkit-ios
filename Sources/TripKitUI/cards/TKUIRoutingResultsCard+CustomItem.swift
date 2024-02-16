//
//  TKUIRoutingResultsCard+CustomItem.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 16/2/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import TGCardViewController

import TripKit

/// Provides arbitrary custom items to inject into the routing results screen.
public protocol TKUIRoutingResultsCustomItemProvider {
  func item(for results: Observable<(TripRequest, [TripGroup])>) -> Observable<TKUIRoutingResultsCard.CustomItem?>

  @MainActor
  func registerCell(for tableView: UITableView)
  
  @MainActor
  func cell(for item: TKUIRoutingResultsCard.CustomItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell
  
  @MainActor
  func show(_ item: TKUIRoutingResultsCard.CustomItem, presenter: TGCardViewController)
}

extension TKUIRoutingResultsCustomItemProvider {
  @MainActor
  func registerCell(for tableView: UITableView) {}
}

extension TKUIRoutingResultsCard {
  public struct CustomItem: Hashable {
    public let payload: AnyHashable
    public let preferredIndex: Int
    
    public init(payload: AnyHashable, preferredIndex: Int = 0) {
      self.payload = payload
      self.preferredIndex = preferredIndex
    }
  }
}
