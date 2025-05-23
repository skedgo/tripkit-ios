//
//  TKUIRoutingResultsViewModel+Content.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa

import TripKit

// MARK: - Map Content

extension TKUIRoutingResultsViewModel {

  typealias MapContent = (all: [TKUIRoutingResultsMapRouteItem], selection: TKUIRoutingResultsMapRouteItem?)
  
}

extension TKUIRoutingResultsViewModel {
  
  static func buildMapContent(all groups: [TripGroup], selection: TKUIRoutingResultsMapRouteItem?) -> MapContent {
    let routeItems = groups.compactMap { $0.preferredRoute }
    let selectedTripGroup = selection?.trip.tripGroup
      ?? groups.first?.request.preferredGroup
      ?? groups.first
    let selectedItem = routeItems.first {$0.trip.tripGroup == selectedTripGroup }
    return (routeItems, selectedItem)
  }
  
}

// MARK: - Building results

extension TKUIRoutingResultsViewModel {
  
  static func fetchTripGroups(_ requests: Observable<(TripRequest, mutable: Bool)>) -> Observable<([TripGroup], mutable: Bool)> {
    return requests.flatMapLatest { tuple -> Observable<([TripGroup], mutable: Bool)> in
      let request = tuple.0
      guard let context = request.managedObjectContext else {
        return .just(([], mutable: tuple.mutable))
      }
      
      let predicate: NSPredicate
      if tuple.mutable {
        // user can hide them, filter by visibility
        predicate = NSPredicate(format: "request = %@ AND visibilityRaw != %@", request, NSNumber(value: TripGroup.Visibility.hidden.rawValue))
      } else {
        // user can't show/hide them; show all
        predicate = NSPredicate(format: "request = %@", request)
      }
      
      return context.rx
        .fetchObjects(
          TripGroup.self,
          sortDescriptors: [NSSortDescriptor(key: "visibleTrip.totalScore", ascending: true)],
          predicate: predicate,
          relationshipKeyPathsForPrefetching: ["visibleTrip", "visibleTrip.segmentReferences"]
        )
        .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
        .map { ($0, mutable: tuple.mutable) }
    }
  }
  
  static func buildSections(_ groups: Observable<([TripGroup], mutable: Bool)>, inputs: UIInput, progress: Observable<TKUIResultsFetcher.Progress>, customItem: Observable<TKUIRoutingResultsCard.CustomItem?>) -> Observable<[Section]> {
    
    let expand = inputs.tappedSectionButton
      .filter { action -> Bool in
        switch action {
        case .trigger: return false
        case .collapse, .expand: return true
        }
      }.map { action -> TripGroup? in
        switch action {
        case .expand(let group): return group
        default: return nil
        }
      }
    
    return Observable
      .combineLatest(
        groups,
        inputs.changedSortOrder.startWith(.score).asObservable(),
        expand.startWith(nil).asObservable(),
        progress,
        customItem.startWith(nil)
      )
      .map(sections)
  }
  
  private static func sections(for groups: ([TripGroup], mutable: Bool), sortBy: TKTripCostType, expand: TripGroup?, progress: TKUIResultsFetcher.Progress, customItem: TKUIRoutingResultsCard.CustomItem?) -> [Section] {
    
    let progressIndicatorSection = Section(items: [.progress])
    let customItemSection = customItem.flatMap { (Section(items: [.customItem($0)]), $0.preferredIndex) }
    
    guard let first = groups.0.first else {
      if case .finished = progress {
        return []
      } else {
        // happens when progress is `locating` and `start`
        return [customItemSection?.0, progressIndicatorSection].compactMap { $0 }
      }
    }
    
    let groupSorters = first.request.sortDescriptors(withPrimary: sortBy)
    let byScoring = (groups.0 as NSArray)
      .sortedArray(using: groupSorters)
      .compactMap { $0 as? TripGroup }
    
    let notCanceled  = byScoring.filter { $0.visibleTrip?.isCanceled == false }
    let cancelations = byScoring.filter { $0.visibleTrip?.isCanceled == true }
    let sorted = notCanceled + cancelations
    
    let tripSorters = first.request.tripTimeSortDescriptors()
    var sections = sorted.compactMap { group -> Section? in
      guard let best = group.visibleTrip else { return nil }
      let items = (Array(group.trips) as NSArray)
        .sortedArray(using: tripSorters)
        .compactMap { $0 as? Trip }
        .compactMap { Item(trip: $0, in: group, filter: groups.mutable) }
      
      let show: [Item]
      let action: SectionAction?
      if let primaryAction = TKUIRoutingResultsCard.config.tripGroupActionFactory?(group) {
        show = items
        action = .init(
          title: primaryAction.title,
          accessibilityLabel: primaryAction.accessibilityLabel,
          payload: .trigger(primaryAction, group),
          isEnabled: primaryAction.isEnabled
        )
      
      } else if items.count > 2, expand == group {
        show = items
        action = .init(title: Loc.Less, payload: .collapse)
      
      } else if items.count > 2 {
        let good = items
          .filter { $0.trip != nil }
          .filter { !$0.trip!.showFaded }
        if good.isEmpty {
          show = Array(items.prefix(2))
        } else {
          show = Array(good.prefix(2))
        }
        action = .init(title: Loc.More, payload: .expand(group))

      } else {
        show = items
        action = nil
      }
      
      let badge: TKMetricClassifier.Classification?
      if let candidate = group.badge, TKUIRoutingResultsCard.config.tripBadgesToShow.contains(candidate) {
        badge = candidate
      } else {
        badge = nil
      }
      
      return Section(
        items: show,
        badge: badge,
        costs: best.costValues,
        action: action
      )
    }

    switch progress {
    case .finished: break
    default: sections.insert(progressIndicatorSection, at: 0)
    }

    if let customItemSection {
      sections.insert(customItemSection.0, at: customItemSection.1)
    }

    return sections
  }
  
}

extension TripRequest {
  var includedTransportModes: String {
    let all = spanningRegion.modeIdentifiers
    let enabled = TKSettings.enabledModeIdentifiers(all)
    return Loc.Showing(enabled.count, ofTransportModes: all.count)
  }
}

extension TripGroup {
  var badge: TKMetricClassifier.Classification? {
    return TKMetricClassifier.classification(for: self)
  }
}

extension Trip {
  var showFaded: Bool {
    return missedBookingWindow     // shuttle, etc., departing too soon
      || isCanceled
      || calculateOffset() < -60  // doesn't match query
  }
}

extension TKUIRoutingResultsViewModel {
  
  /// An item in a section on the results screen
  enum Item {
    
    /// A regular/expanded trip
    /// Also include update URL to allow checking when a trip changed and then update the cell.
    case trip(Trip, lastUpdateURL: String?)
    
    case progress
    
    case customItem(TKUIRoutingResultsCard.CustomItem)
    
    var trip: Trip? {
      switch self {
      case .trip(let trip, _): return trip
      case .progress, .customItem: return nil
      }
    }
    
    var customItem: TKUIRoutingResultsCard.CustomItem? {
      switch self {
      case .customItem(let customItem): return customItem
      case .trip, .progress: return nil
      }
    }

  }
  
  enum ActionPayload {
    case expand(TripGroup)
    case collapse
    case trigger(TKUIRoutingResultsCard.TripGroupAction, TripGroup)
  }
  
  struct SectionAction {
    var title: String
    var accessibilityLabel: String? = nil
    var payload: ActionPayload
    var isEnabled: Bool = true
  }
  
  /// A section on the results screen, which consists of various sorted items
  struct Section {
    var items: [Item]
    
    var badge: TKMetricClassifier.Classification? = nil
    var costs: [TKTripCostType: String] = [:]
    var action: SectionAction? = nil
  }
}

extension TKMetricClassifier.Classification {
  
  var icon: UIImage? {
    switch self {
    case .cheapest: return .badgeMoney
    case .easiest: return .badgeLike
    case .fastest: return .badgeLightning
    case .greenest: return .badgeLeaf
    case .healthiest: return .badgeHeart
    case .recommended: return .badgeCheck
    }
  }
  
  var text: String {
    switch self {
    case .cheapest: return Loc.BadgeCheapest
    case .easiest: return Loc.BadgeEasiest
    case .fastest: return Loc.BadgeFastest
    case .greenest: return Loc.BadgeGreenest
    case .healthiest: return Loc.BadgeHealthiest
    case .recommended: return Loc.BadgeRecommended
    }
  }
  
  var color: UIColor {
    switch self {
    case .cheapest: return #colorLiteral(red: 1, green: 0.5529411765, blue: 0.1058823529, alpha: 1)
    case .easiest: return #colorLiteral(red: 0.137254902, green: 0.6941176471, blue: 0.368627451, alpha: 1)
    case .fastest: return #colorLiteral(red: 1, green: 0.7490196078, blue: 0, alpha: 1)
    case .greenest: return #colorLiteral(red: 0, green: 0.6588235294, blue: 0.5607843137, alpha: 1)
    case .healthiest: return #colorLiteral(red: 0.8823529412, green: 0.3568627451, blue: 0.4470588235, alpha: 1)
    case .recommended: return #colorLiteral(red: 0.09411764706, green: 0.5019607843, blue: 0.9058823529, alpha: 1)
    }
  }
}

extension TKUIRoutingResultsViewModel.Item {
  
  fileprivate init?(trip: Trip, in group: TripGroup, filter: Bool) {
    guard filter else { self = .trip(trip, lastUpdateURL: trip.updateURLString); return }
    
    switch group.visibility {
    case .hidden: return nil
    case .full:   self = .trip(trip, lastUpdateURL: trip.logURLString)
    }
  }
  
}

// MARK: - Map content

public func ==(lhs: TKUIRoutingResultsMapRouteItem, rhs: TKUIRoutingResultsMapRouteItem) -> Bool {
  return lhs.trip.objectID == rhs.trip.objectID
}
extension TKUIRoutingResultsMapRouteItem: Equatable { }

extension TripGroup {
  fileprivate var preferredRoute: TKUIRoutingResultsMapRouteItem? {
    guard let trip = visibleTrip else { return nil }
    return TKUIRoutingResultsMapRouteItem(trip)
  }
}

extension Array where Element == TKUIRoutingResultsViewModel.Section {
  func find(_ mapRoute: TKUIRoutingResultsMapRouteItem?) -> TKUIRoutingResultsViewModel.Item? {
    guard let mapRoute = mapRoute else { return nil }
    for section in self {
      for item in section.items {
        if item.trip == mapRoute.trip {
          return item
        }
      }
    }
    return nil
  }
  
  var bestItem: TKUIRoutingResultsViewModel.Item? {
    return first?.items.first // Assuming we're sorting by best
  }
}

// MARK: - RxDataSources protocol conformance

func ==(lhs: TKUIRoutingResultsViewModel.Item, rhs: TKUIRoutingResultsViewModel.Item) -> Bool {
  switch (lhs, rhs) {
  case (.trip(let left, let leftURL), .trip(let right, let rightURL)):
    return left.objectID == right.objectID
        && leftURL == rightURL
  case (.progress, .progress): return true
  case (.customItem(let left), .customItem(let right)): return left == right
  default: return false
  }
}
extension TKUIRoutingResultsViewModel.Item: Equatable { }

extension TKUIRoutingResultsViewModel.Item: IdentifiableType {
  typealias Identity = String
  var identity: Identity {
    switch self {
    case .trip(let trip, _): return trip.objectID.uriRepresentation().absoluteString
    case .progress: return "progress_indicator"
    case .customItem: return "customItem" // should only ever have one
    }
  }
}

extension TKUIRoutingResultsViewModel.Section: AnimatableSectionModelType {
  typealias Identity = String
  typealias Item = TKUIRoutingResultsViewModel.Item
  
  init(original: TKUIRoutingResultsViewModel.Section, items: [TKUIRoutingResultsViewModel.Item]) {
    self = original
    self.items = items
  }
  
  var identity: Identity {
    let itemIdentity = items.first?.identity ?? "Empty"
    
    // `AnimatableSectionModelType` seems to only pick up changes to items
    // not to the section otherwise itself. But badge + cost are somewhat
    // dynamic when new trips pop in, or a real-time or booking update changes
    // a trip's metrics. So we smush them into the identity to force an update.
    return itemIdentity + (action?.title ?? "") + (badge?.rawValue ?? "") + "\(costs.hashValue)"
  }
}
