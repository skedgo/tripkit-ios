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
    return TKBuzzInfoProvider.rx_fetchTransitAlertMappings(forRegion: region)
      .map { self.groupAlertMappings($0) }
      .map { self.alertSections(from: $0) }
      .share(replay: 1)
  }()
  
  public init(region: SVKRegion) {
    self.region = region
  }
  
  // MARK: -
  
  private func groupAlertMappings(_ mappings: [API.AlertMapping]) -> [String: [AlertGroup]] {
    var alertGroupsByModes: [String: [AlertGroup]] = [:]
    
    for mapping in mappings {
      mapping.routes?.forEach {
        // TODO: Prefer to just use identifier.
        let mode = $0.modeInfo.identifier ?? $0.modeInfo.alt
        if var existingGroups = alertGroupsByModes[mode] {
          let existingIds  = existingGroups.map { $0.route.id }
          if let index = existingIds.index(of: $0.id) {
            var currentAlerts = existingGroups[index].alerts
            currentAlerts.append(mapping.alert)
            existingGroups[index].alerts = currentAlerts
            alertGroupsByModes[mode] = existingGroups
          } else {
            let newGroup = AlertGroup(route: $0, alerts: [mapping.alert])
            existingGroups.append(newGroup)
            alertGroupsByModes[mode] = existingGroups
          }
        } else {
          let newGroup = AlertGroup(route: $0, alerts: [mapping.alert])
          alertGroupsByModes[mode] = [newGroup]
        }
      }
    }
    
    return alertGroupsByModes
  }
  
  private func alertSections(from alertGroupsByMode: [String: [AlertGroup]]) -> [AlertSection] {
    var sections: [AlertSection] = []
    
    alertGroupsByMode.forEach { (key, value) in
      let sorted = value.sorted(by: {$0.title < $1.title})
      let items = sorted.map { AlertItem(alertGroup: $0) }
      let section = AlertSection(header: key, items: items)
      sections.append(section)
    }
    
    return sections
  }
  
}

extension API.Route {
  var title: String {
    return number ?? name ?? id
  }
}

// MARK: -

struct AlertGroup {
  /// Each group is identifiable by a route. The route is affected
  /// by the alerts in the group.
  var route: API.Route
  
  /// These are the alerts affecting the route.
  var alerts: [API.Alert]
  
  /// Title for the group. This is mainly used for sorting mapping groups.
  var title: String { return route.title }
}

// MARK: -

struct AlertItem {
  var alertGroup: AlertGroup
}

// MARK: -

struct AlertSection {
  var header: String
  var items: [Item]
  var icon: UIImage? {
    guard let imageName = items.first?.alertGroup.route.modeInfo.localImageName else { return nil }
    return SGStyleManager.image(forModeImageName: imageName, isRealTime: false, of: .listMainMode)
  }
}

extension AlertSection: SectionModelType {
  typealias Item = AlertItem
  
  init(original: AlertSection, items: [Item]) {
    self = original
    self.items = items
  }
}
