//
//  TKUINearbyViewModel+HomeCard.swift
//  TripGoAppKit
//
//  Created by Brian Huang on 25/8/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

import TripKit

extension TKUINearbyViewModel: TKUIHomeComponentViewModel {
  
  public static func buildInstance(from inputs: TKUIHomeComponentInput) -> Self {
    let instance = self.init(
      limitTo: "pt_pub",
      strictModeMatch: false,
      mapInput: .init(mapRect: inputs.mapRect)
    )
    Self.homeInstance = instance
    return instance
  }
  
  public var identity: String { "single-nearby-section" }
  
  public var customizerItem: TKUIHomeCardCustomizerItem? {
    .init(name: Loc.NearMe, icon: .iconArrowUp)
  }

  public var homeCardSection: Driver<TKUIHomeComponentContent> {
    sections.map { sections in
      let nearbyItems = sections.flatMap(\.items).prefix(5)
      let configuration = TKUIHomeHeaderConfiguration(title: Loc.NearMe)
      return TKUIHomeComponentContent(items: Array(nearbyItems), header: configuration)
    }
  }
  
  public var nextAction: Signal<TKUIHomeCard.ComponentAction> {
    return mapAnnotationToSelect.map { .handleSelection(.annotation($0), component: self) }
  }

  public func cell(for item: TKUIHomeComponentItem, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell? {
    guard let nearbyItem = item as? TKUINearbyViewModel.Item else { return nil }
    
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUINearbyCell.reuseIdentifier, for: indexPath) as? TKUINearbyCell else {
      assertionFailure("Unable to instantiate an instance of TKUINearbyCell")
      return nil
    }
    
    cell.nearbyItem = nearbyItem
    return cell
  }
  
  public func registerCell(with tableView: UITableView) {
    tableView.register(TKUINearbyCell.nib, forCellReuseIdentifier: TKUINearbyCell.reuseIdentifier)
  }
  
}

extension TKUINearbyViewModel.Item: TKUIHomeComponentItem {
}
