//
//  TKUIResultsViewModel+Content.swift
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

extension TKUIResultsViewModel {
  
}

// MARK: - Map Content

extension TKUIResultsViewModel {

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

extension TKUIResultsViewModel {
  
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

extension TKUIResultsViewModel {
  
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
    let expand = inputs.selected
      .map { item -> TripGroup? in
        switch item {
        case .nano, .trip, .lessIndicator: return nil
        case .moreIndicator(let group): return group
        }
    }
    
    return Observable
      .combineLatest(groups, inputs.changedSortOrder.startWith(.score).asObservable(), expand.startWith(nil).asObservable())
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
      if items.count > 2, expand == group {
        show = items + [.lessIndicator(group)]
      } else if items.count > 2 {
        let good = items.filter { !($0.trip?.showFaded ?? true) }
        show = good.prefix(2) + [.moreIndicator(group)]
      } else {
        show = items
      }
      return Section(items: show, badge: group.badge, costs: best.costValues)
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

extension TKUIResultsViewModel {
  
  /// An item in a section on the results screen
  public enum Item {
    
    /// A regular/expanded trip
    case trip(Trip)
    
    /// A minimised trip
    case nano(Trip)
    
    case moreIndicator(TripGroup)
    case lessIndicator(TripGroup)
    
    var trip: Trip? {
      switch self {
      case .nano(let trip): return trip
      case .trip(let trip): return trip
      case .moreIndicator, .lessIndicator: return nil
      }
    }
    
  }
  
  /// A section on the results screen, which consists of various sorted items
  public struct Section {
    public var items: [Item]
    
    public var badge: TKMetricClassifier.Classification?
    var costs: [NSNumber: String]
  }
}

extension TKMetricClassifier.Classification {
  
  var icon: UIImage? {
    switch self {
    case .easiest: return UIImage.iconRelax
    case .greenest: return UIImage.iconTree
    case .fastest: return UIImage.iconTime
    case .healthiest: return UIImage.iconRun
    case .cheapest: return UIImage.iconMoney
    case .recommended: return nil
    }
  }
  
  var text: String {
    switch self {
    case .easiest: return Loc.BadgeEasiest
    case .greenest: return Loc.BadgeGreenest
    case .fastest: return Loc.BadgeFastest
    case .healthiest: return Loc.BadgeHealthiest
    case .cheapest: return Loc.BadgeCheapest
    case .recommended: return Loc.BadgeRecommended
    }
  }
  
  var color: UIColor {
    switch self {
    case .easiest, .cheapest, .fastest: return #colorLiteral(red: 0.7921568627, green: 0.2549019608, blue: 0.0862745098, alpha: 1)
    case .greenest, .healthiest: return #colorLiteral(red: 0.1254901961, green: 0.7882352941, blue: 0.4156862745, alpha: 1)
    case .recommended: return #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
    }
  }
}

extension TKUIResultsViewModel.Item {
  
  fileprivate init?(trip: Trip, in group: TripGroup) {
    switch group.visibility {
    case .hidden: return nil
    case .mini:   self = .nano(trip)
    case .full:   self = .trip(trip)
    }
  }
  
}

// MARK: - Map content

public func ==(lhs: TKUIResultsViewModel.MapRouteItem, rhs: TKUIResultsViewModel.MapRouteItem) -> Bool {
  return lhs.trip.objectID == rhs.trip.objectID
}
extension TKUIResultsViewModel.MapRouteItem: Equatable { }

extension TripGroup {
  fileprivate var preferredRoute: TKUIResultsViewModel.MapRouteItem? {
    guard let trip = visibleTrip else { return nil }
    return TKUIResultsViewModel.MapRouteItem(trip)
  }
}

extension Array where Element == TKUIResultsViewModel.Section {
  func find(_ mapRoute: TKUIResultsViewModel.MapRouteItem?) -> TKUIResultsViewModel.Item? {
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
  
  var bestItem: TKUIResultsViewModel.Item? {
    return first?.items.first // Assuming we're sorting by best
  }
}

// MARK: - ?

extension TKUIResultsViewModel {
  
  //  func allQueriesDidFinish(with error: NSError?) {
  //    // TODO: Call this again?
  //
  //    guard let request = self.rx_request.value, !request.hasTrips() else { return }
  //
  //    if let error = error {
  //      rx_error.onNext(error)
  //
  //    } else {
  //      // We have a request, there was no explicit error during routing.
  //      let info = [
  //        NSLocalizedDescriptionKey: Loc.NoRoutesFound,
  //        NSLocalizedRecoverySuggestionErrorKey: Loc.PleaseAdjustYourQuery,
  //        ]
  //
  //      let noTrips = NSError(domain: "com.buzzhives.TripGo", code: 872631, userInfo: info)
  //      rx_error.onNext(noTrips)
  //    }
  //  }
  
}



// MARK: - RxDataSources

public func ==(lhs: TKUIResultsViewModel.Item, rhs: TKUIResultsViewModel.Item) -> Bool {
  switch (lhs, rhs) {
  case (.trip(let left), .trip(let right)): return left.objectID == right.objectID
  case (.nano(let left), .nano(let right)): return left.objectID == right.objectID
  case (.moreIndicator, .moreIndicator): return true
  default: return false
  }
}
extension TKUIResultsViewModel.Item: Equatable { }

extension TKUIResultsViewModel.Item: IdentifiableType {
  public typealias Identity = String
  public var identity: Identity {
    switch self {
    case .trip(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .nano(let trip): return trip.objectID.uriRepresentation().absoluteString
    case .moreIndicator(let group): return "more-\(group.objectID.uriRepresentation().absoluteString)"
    case .lessIndicator(let group): return "less-\(group.objectID.uriRepresentation().absoluteString)"
    }
  }
}

extension TKUIResultsViewModel.Section: AnimatableSectionModelType {
  public typealias Identity = String
  public typealias Item = TKUIResultsViewModel.Item
  
  public init(original: TKUIResultsViewModel.Section, items: [TKUIResultsViewModel.Item]) {
    self = original
    self.items = items
  }
  
  public var identity: Identity { return items.first?.identity ?? "Empty" }
}
