//
//  TKSectionedAlertViewModel.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 15/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources

public class TKSectionedAlertViewModel {
  
  public let region: SVKRegion
  
  private let disposeBag = DisposeBag()
  
  lazy var sections: Observable<[AlertSection]> = {
    return TKBuzzInfoProvider.rx_fetchTransitAlerts(forRegion: region)
      .map { self.alertItems(from: $0) }
      .map { self.alertSections(from: $0) }
      .share(replay: 1)
  }()
  
  public init(region: SVKRegion) {
    self.region = region
  }
  
  // MARK: -
  
  private func alertItems(from decoded: [API.AlertMapping]) -> [String: [String]] {
    var itemsByModes: [String: [String]] = [:]
    decoded.forEach { (mapping) in
      let mode = mapping.modeIdentifier ?? "Unknown mode"
      if let existing = itemsByModes[mode] {
        let existingSet = Set(existing)
        let newSet = Set(mapping.routeIDs)
        itemsByModes[mode] = Array(existingSet.union(newSet))
      } else {
        itemsByModes[mode] = mapping.routeIDs
      }
    }
    return itemsByModes
  }
  
  private func alertSections(from itemsByMode: [String: [String]]) -> [AlertSection] {
    var sections: [AlertSection] = []
    
    itemsByMode.forEach { (key, value) in
      let items = value.map { AlertItem(name: $0) }.sorted(by: { $0.name < $1.name })
      let section = AlertSection(header: key, items: items)
      sections.append(section)
    }
    
    return sections
  }
  
}

// MARK: -

extension API.AlertMapping {
  
  var routeIDs: [String] {
    guard let routes = self.routes else { return ["Unknown"] }
    return routes.flatMap { $0.number ?? $0.name ?? nil }
  }
  
}

// MARK: -

struct AlertItem {
  var name: String
}

// MARK: -

struct AlertSection {
  var header: String
  var items: [Item]
}

extension AlertSection: SectionModelType {
  typealias Item = AlertItem
  
  init(original: AlertSection, items: [Item]) {
    self = original
    self.items = items
  }
}
