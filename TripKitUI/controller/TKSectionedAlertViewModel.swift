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
  
  lazy var sections: Observable<[AlertSection]> = { [unowned self] in 
    return TKBuzzInfoProvider.rx_fetchTransitAlerts(forRegion: region)
      .map { self.alertItems(from: $0) }
      .map { self.alertSections(from: $0) }
      .share(replay: 1)
  }()
  
  public init(region: SVKRegion) {
    self.region = region
  }
  
  // MARK: -
  
  private func alertItems(from decoded: [API.AlertMapping]) -> [String: [AlertGroup]] {
    var alertGroupsByModes: [String: [AlertGroup]] = [:]
    var tmp: [AlertGroup] = []
    decoded.forEach { mapping in
      let mode = mapping.modeIdentifier ?? "Unknown mode"
      if let existing = alertGroupsByModes[mode] {
        var currentRouteIds = existing.map { $0.routeId }
        tmp = existing
        mapping.routes?.forEach {
          if let index = currentRouteIds.index(of: $0.identifier) {
            var currentGroup = tmp[index]
            currentGroup.alerts.append(mapping)
            tmp[index] = currentGroup
            alertGroupsByModes[mode] = tmp
          } else {
            let newGroup = AlertGroup(routeId: $0.identifier, alerts: [mapping])
            tmp.append(newGroup)
            currentRouteIds.append($0.identifier)
            alertGroupsByModes[mode] = tmp
          }
        }
      } else {
        var groups: [AlertGroup] = []
        mapping.routes?.forEach {
          let newGroup = AlertGroup(routeId: $0.identifier, alerts: [mapping])
          groups.append(newGroup)
        }
        alertGroupsByModes[mode] = groups
      }
    }
    
    return alertGroupsByModes
  }
  
  private func alertSections(from alertGroupsByMode: [String: [AlertGroup]]) -> [AlertSection] {
    var sections: [AlertSection] = []
    
    alertGroupsByMode.forEach { (key, value) in
      let items = value.map { AlertItem(alertGroup: $0) }
      let section = AlertSection(header: key, items: items)
      sections.append(section)
    }
    
    return sections
  }
  
}

// MARK: -

extension API.AlertMapping {
  
  var routeIds: [String] {
    guard let routes = self.routes else { return [] }
    return routes.map { $0.identifier }
  }
  
}

extension API.Route {
  
  var identifier: String {
    return self.number ?? self.name ?? self.id ?? "genericId"
  }
  
}

// MARK: -

struct AlertGroup {
  var routeId: String
  var alerts: [API.AlertMapping]
  
  func componentAlerts() -> [API.Alert] {
    return alerts.map { $0.alert }
  }
}

// MARK: -

struct AlertItem {
  var alertGroup: AlertGroup
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
