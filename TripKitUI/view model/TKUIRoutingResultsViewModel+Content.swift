//
//  TKUIRoutingResultsViewModel+Content.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 01.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

// MARK: - List content

extension TKUIRoutingResultsViewModel {
  
}

// MARK: - Map Content

extension TKUIRoutingResultsViewModel {

  /// An item to be displayed on the map
  public struct MapRouteItem {
    fileprivate let trip: Trip
    
    public let polyline: TKRoutePolyline
    public let selectionIdentifier: String
    
    init?(_ trip: Trip) {
      self.trip = trip
      self.selectionIdentifier = trip.objectID.uriRepresentation().absoluteString
      
      let displayableShapes = trip.segments(with: .onMap)
        .compactMap { ($0 as? TKSegment)?.shortedShapes() }   // Only include those with shapes
        .flatMap { $0.filter { $0.routeIsTravelled } } // Flat list of travelled shapes
      
      let route = displayableShapes
        .reduce(into: TKColoredRoute(path: [], identifier: selectionIdentifier)) { $0.append($1.sortedCoordinates ?? []) }
      
      guard let polyline = TKRoutePolyline(for: route) else { return nil }
      self.polyline = polyline
    }
  }

  public typealias MapContent = (all: [MapRouteItem], selection: MapRouteItem?)

  
}

extension TKUIRoutingResultsViewModel {
  
  static func buildMapContent(all groups: [TripGroup], selection: MapRouteItem?) -> MapContent {
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
  
  static func fetchTripGroups(_ requests: Observable<TripRequest?>) -> Observable<[TripGroup]> {
    return requests.flatMapLatest { request -> Observable<[TripGroup]> in
      guard let request = request, let context = request.managedObjectContext else {
        return .just([])
      }
      
      return context.rx
        .fetchObjects(
          TripGroup.self,
          sortDescriptors: [NSSortDescriptor(key: "visibleTrip.totalScore", ascending: true)],
          predicate: NSPredicate(format: "toDelete = NO AND request = %@ AND visibilityRaw != %@", request, NSNumber(value: TripGroupVisibility.hidden.rawValue)),
          relationshipKeyPathsForPrefetching: ["visibleTrip", "visibleTrip.segmentReferences"]
        )
        .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
    }
  }
  
  static func buildSections(_ groups: Observable<[TripGroup]>, inputs: UIInput) -> Observable<[Section]> {
    return Observable
      .combineLatest(
        groups,
        inputs.changedSortOrder.startWith(.score).asObservable(),
        inputs.tappedToggleButton.startWith(nil).asObservable()
      )
      .map(sections)
  }
  
  private static func sections(for groups: [TripGroup], sortBy: TKTripCostType, expand: TripGroup?) -> [Section] {
    guard let first = groups.first else { return [] }
    
    let groupSorters = first.request.sortDescriptors(withPrimary: sortBy)
    let sorted = (groups as NSArray).sortedArray(using: groupSorters).compactMap { $0 as? TripGroup }
    
    let tripSorters = first.request.tripTimeSortDescriptors()
    return sorted.compactMap { group -> Section? in
      guard let best = group.visibleTrip else { return nil }
      let items = (Array(group.trips) as NSArray)
        .sortedArray(using: tripSorters)
        .compactMap { $0 as? Trip }
        .compactMap { Item(trip: $0, in: group) }
      
      let show: [Item]
      let toggleButton: SectionToggle?
      if items.count > 2, expand == group {
        show = items
        toggleButton = (title: "Less", payload: nil) // TODO: Localise
      } else if items.count > 2 {
        let good = items.filter { !$0.trip.showFaded }
        show = Array(good.prefix(2))
        toggleButton = (title: "More", payload: group) // TODO: Localise
      } else {
        show = items
        toggleButton = nil
      }
      return Section(items: show, badge: group.badge, costs: best.costValues, toggleButton: toggleButton)
    }
  }
}

extension TripRequest {
  var includedTransportModes: String {
    let all = spanningRegion().modeIdentifiers
    let visible = Set(all).subtracting(TKUserProfileHelper.hiddenModeIdentifiers)
    return Loc.Showing(visible.count, ofTransportModes: all.count)
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
      || calculateOffset() < -1  // doesn't match query
  }
}

extension TKUIRoutingResultsViewModel {
  
  /// An item in a section on the results screen
  public enum Item {
    
    /// A regular/expanded trip
    case trip(Trip)
    
    /// A minimised trip
    case nano(Trip)
    
    var trip: Trip {
      switch self {
      case .nano(let trip): return trip
      case .trip(let trip): return trip
      }
    }
  }
  
  public typealias SectionToggle = (title: String, payload: TripGroup?)
  
  /// A section on the results screen, which consists of various sorted items
  public struct Section {
    public var items: [Item]
    
    public var badge: TKMetricClassifier.Classification?
    var costs: [NSNumber: String]
    public let toggleButton: SectionToggle?
  }
}

extension TKMetricClassifier.Classification {
  
  var icon: UIImage? {
    switch self {
    case .cheapest: return .badgeMoney
    case .easiest: return .badgeLeaf
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
  
  fileprivate init?(trip: Trip, in group: TripGroup) {
    switch group.visibility {
    case .hidden: return nil
    case .mini:   self = .nano(trip)
    case .full:   self = .trip(trip)
    }
  }
  
}

// MARK: - Map content

public func ==(lhs: TKUIRoutingResultsViewModel.MapRouteItem, rhs: TKUIRoutingResultsViewModel.MapRouteItem) -> Bool {
  return lhs.trip.objectID == rhs.trip.objectID
}
extension TKUIRoutingResultsViewModel.MapRouteItem: Equatable { }

extension TripGroup {
  fileprivate var preferredRoute: TKUIRoutingResultsViewModel.MapRouteItem? {
    guard let trip = visibleTrip else { return nil }
    return TKUIRoutingResultsViewModel.MapRouteItem(trip)
  }
}

extension Array where Element == TKUIRoutingResultsViewModel.Section {
  func find(_ mapRoute: TKUIRoutingResultsViewModel.MapRouteItem?) -> TKUIRoutingResultsViewModel.Item? {
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

// MARK: - RxDataSources

public func ==(lhs: TKUIRoutingResultsViewModel.Item, rhs: TKUIRoutingResultsViewModel.Item) -> Bool {
  switch (lhs, rhs) {
  case (.trip(let left), .trip(let right)): return left.objectID == right.objectID
  case (.nano(let left), .nano(let right)): return left.objectID == right.objectID
  default: return false
  }
}
extension TKUIRoutingResultsViewModel.Item: Equatable { }

extension TKUIRoutingResultsViewModel.Item: IdentifiableType {
  public typealias Identity = String
  public var identity: Identity {
    switch self {
    case .trip(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .nano(let trip): return trip.objectID.uriRepresentation().absoluteString
    }
  }
}

extension TKUIRoutingResultsViewModel.Section: AnimatableSectionModelType {
  public typealias Identity = String
  public typealias Item = TKUIRoutingResultsViewModel.Item
  
  public init(original: TKUIRoutingResultsViewModel.Section, items: [TKUIRoutingResultsViewModel.Item]) {
    self = original
    self.items = items
  }
  
  public var identity: Identity { return items.first?.identity ?? "Empty" }
}
