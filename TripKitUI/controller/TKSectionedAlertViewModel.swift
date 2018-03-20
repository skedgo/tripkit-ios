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
      .map { self.groupAlertMappings($0) }
      .map { self.alertSections(from: $0) }
      .share(replay: 1)
  }()
  
  public init(region: SVKRegion) {
    self.region = region
  }
  
  // MARK: -
  
  private func groupAlertMappings(_ mappings: [API.AlertMapping]) -> [String: [AlertMappingGroup]] {
    var alertGroupsByModes: [String: [AlertMappingGroup]] = [:]
    var tmp: [AlertMappingGroup] = []
    mappings.forEach { mapping in
      let mode = mapping.modeIdentifier ?? "Unknown mode"
      if let existing = alertGroupsByModes[mode] {
        var currentRouteIds = existing.map { $0.route.label }
        tmp = existing
        mapping.routes?.forEach {
          if let index = currentRouteIds.index(of: $0.label) {
            var currentGroup = tmp[index]
            currentGroup.mappings.append(mapping)
            tmp[index] = currentGroup
            alertGroupsByModes[mode] = tmp
          } else {
            let newGroup = AlertMappingGroup(route: $0, mappings: [mapping])
            tmp.append(newGroup)
            currentRouteIds.append($0.label)
            alertGroupsByModes[mode] = tmp
          }
        }
      } else {
        var groups: [AlertMappingGroup] = []
        mapping.routes?.forEach {
          let newGroup = AlertMappingGroup(route: $0, mappings: [mapping])
          groups.append(newGroup)
        }
        alertGroupsByModes[mode] = groups
      }
    }
    
    return alertGroupsByModes
  }
  
  private func alertSections(from alertGroupsByMode: [String: [AlertMappingGroup]]) -> [AlertSection] {
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
    return routes.map { $0.label }
  }
  
}

extension API.Route {
  
  var label: String {
    return self.number ?? self.name ?? self.id ?? "genericId"
  }
  
}

// MARK: -

struct AlertMappingGroup {
  var route: API.Route
  var mappings: [API.AlertMapping]
  
  func alerts() -> [API.Alert] {
    return mappings.map { $0.alert }
  }
}

// MARK: -

struct AlertItem {
  var alertGroup: AlertMappingGroup
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
