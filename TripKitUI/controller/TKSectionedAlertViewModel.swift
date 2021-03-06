//
//  TKSectionedAlertViewModel.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 15/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

class TKSectionedAlertViewModel {
  
  enum State {
    case loading
    case content([Section])
  }
  
  let state: Driver<State>
  
  private let disposeBag = DisposeBag()
  
  init(
    region: SVKRegion,
    searchText: Observable<String>
  ) {
    let allRouteAlerts = TKBuzzInfoProvider
      .rx_fetchTransitAlertMappings(forRegion: region)
      .map { TKSectionedAlertViewModel.groupAlertMappings($0) }
    
    state = Observable.combineLatest(allRouteAlerts, searchText.startWith("")) { TKSectionedAlertViewModel.buildSections(from: $0, filter: $1) }
      .asDriver(onErrorJustReturn: [])
      .map { sections -> State in
        return .content(sections)
      }
      .startWith(.loading)
  }
  
  // MARK:
  
  struct Item {
    let alertGroup: RouteAlerts
    
    var alerts: [API.Alert] {
      return alertGroup.alerts
    }
  }
  
  struct Section {
    let modeGroup: ModeGroup
    var items: [Item]
    
    var header: String? { return modeGroup.title }
    var color: UIColor? { return modeGroup.color }
  }
  
  // MARK: -
  
  static func groupAlertMappings(_ mappings: [API.AlertMapping]) -> [ModeGroup: [RouteAlerts]] {
    
    // Firstly, we group all alerts by their mode
    let groupedModes = Dictionary(grouping: mappings) { mapping -> ModeGroup in
      if let modeInfo = mapping.modeInfo ?? mapping.routes?.first?.modeInfo {
        return ModeGroup(modeInfo)
      } else {
        return ModeGroup.dummy
      }
    }
    
    // Secondly, within each mode, we group alerts by route
    return groupedModes.mapValues { mappings -> [RouteAlerts] in
      
      // Mappings are `[Alert: [Route]]`. Here we invert this to `[Route: [Alert]]`
      let alertsByRoute: [API.Route: [API.Alert]] = mappings.reduce(into: [:]) { acc, mapping in
        mapping.routes?.forEach { route in
          var alerts = acc[route] ?? []
          alerts.append(mapping.alert)
          acc[route] = alerts
        }
      }
      return alertsByRoute.map {
        return RouteAlerts(route: $0.key, alerts: $0.value)
      }
    }
  }
  
  private static func buildSections(from alertGroupsByMode: [ModeGroup: [RouteAlerts]], filter: String) -> [Section] {
    
    return alertGroupsByMode.reduce(into: []) { acc, tuple in
      let filtered = tuple.1.filter { filter.isEmpty || $0.title.contains(filter) }
      guard !filtered.isEmpty else { return }
      let sorted = filtered.sorted(by: {$0.title < $1.title})
      let items = sorted.map { Item(alertGroup: $0) }
      acc.append(Section(modeGroup: tuple.0, items: items))
    }
  }
  
}

// MARK: -

extension API.Route {
  var title: String {
    return number ?? name ?? id
  }
}

// MARK: -

struct ModeGroup {
  let title: String
  let color: SGKColor?
  
  init(_ modeInfo: ModeInfo) {
    self.title = modeInfo.descriptor ?? modeInfo.alt
    self.color = modeInfo.color
  }
  
  private init() {
    self.title = ""
    self.color = nil
  }
  
  fileprivate static let dummy = ModeGroup()
}

func == (lhs: ModeGroup, rhs: ModeGroup) -> Bool {
  return lhs.title == rhs.title
}
extension ModeGroup: Equatable {}
extension ModeGroup: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(title)
  }
}

struct RouteAlerts {
  /// Each group is identifiable by a route. The route is affected
  /// by the alerts in the group.
  let route: API.Route
  
  /// These are the alerts affecting the route.
  var alerts: [API.Alert]
  
  /// Title for the group. This is mainly used for sorting mapping groups.
  var title: String { return route.title }
}

// MARK: - RxDataSources

extension TKSectionedAlertViewModel.Section: SectionModelType {
  typealias Item = TKSectionedAlertViewModel.Item
  
  init(original: TKSectionedAlertViewModel.Section, items: [Item]) {
    self = original
    self.items = items
  }
}
