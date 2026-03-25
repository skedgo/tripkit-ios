//
//  TKUIRoutingResultsCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TGCardViewController

import TripKit

public extension TKUIRoutingResultsCard {
  
  typealias TripGroupAction = TKUICardAction<TKUIRoutingResultsCard, TripGroup>

  /// Enumeration used when the user taps a button to get help, see `TKUIRoutingResultsCard.Configuration.contactCustomerSupport`
  enum SupportType {
    /// User tried querying for a from/to pair that isn't supported yet
    case unsupportedQuery(TripRequest)
    
    /// User encountered an unidentifier routing error
    case routingError(Error, TripRequest)
  }
  
  /// Configuration of any `TKUIRoutingResultsCard`.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUIRoutingResultsCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
    public typealias RoutingModeRequestGroupAdjuster = (Set<String>, Set<Set<String>>) -> Set<Set<String>>
    
    /// Runtime-injected mode shown alongside the region's routing modes.
    public struct CustomMode {
      public let identifier: String
      public let title: String
      public let subtitle: String?
      public let icon: TKImage
      
      public init(identifier: String, title: String, subtitle: String? = nil, icon: TKImage) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
      }
      
      fileprivate var routingMode: TKRegion.RoutingMode {
        TKRegion.RoutingMode(identifier: identifier, title: title, subtitle: subtitle, icon: icon)
      }
    }
    
    /// Set this to specify where the card should be placed when it's loaded.
    ///
    /// Defaults to `.peaking` position
    public var initialCardPosition: TGCardPosition = .peaking
    
    /// Set this to limit routing results to a certain transport modes.
    ///
    /// If this is set, the routing card will not display the Transport button,
    /// which allows users to show or hide transport modes when results are
    /// presented.
    ///
    /// Defaults to nil, which means the SDK will read from `TKSettings`
    public var limitToModes: Set<String>? = nil
    
    /// Additional routing modes to inject into the runtime mode picker.
    public var customModes: [CustomMode] = []
    
    /// Adjust the grouped backend routing requests derived from the current
    /// picker selection.
    ///
    /// The first set contains the selected picker identifiers exactly as chosen
    /// by the user, including any injected custom mode identifiers.
    ///
    /// The second set contains the default backend request groups after custom
    /// identifiers have been removed and the remaining backend identifiers have
    /// been grouped via `TKTransportMode.groupModeIdentifiers(...)`.
    ///
    /// Return the complete set of backend request groups that should actually be
    /// sent. Each inner set represents one routing request's mode identifiers.
    ///
    /// This can be used to inject extra modes into a mixed-modal request
    /// without creating additional single-mode requests, or to merge several
    /// backend identifiers into a single request.
    public var routingModeRequestGroupAdjuster: RoutingModeRequestGroupAdjuster? = nil
    
    /// Set this to add a button for a trip group.
    ///
    /// Called when a results card gets presented.
    public var tripGroupActionFactory: ((TripGroup) -> TripGroupAction?)?

    /// Set this to have a button on the results card to contact customer support
    /// when the user is encountering errors.
    ///
    /// Called when the user taps the button.
    public var contactCustomerSupport: ((TKUIRoutingResultsCard, SupportType) -> Void)?
    
    /// Set this to use your own map manager. You can use this in combination
    /// with `TGCardViewController.builder` to use a map other than Apple's
    /// MapKit.
    ///
    /// Defaults to using `TKUIRoutingResultsMapManager`.
    public var mapManagerFactory: (@MainActor (MKAnnotation?, Bool) -> TKUIRoutingResultsMapManagerType) = {
      TKUIRoutingResultsMapManager(destination: $0, zoomToDestination: $1)
    }
    
    /// An optional list of autocompletion data providers. This list will be used by an instance of
    /// `TKUILocationSearchViewController`, which is presented when users click on
    /// the origin or destination labels. If none was provided, the `TKAppleGeocoder` and
    /// `TKTripGoGeocoder` will be used.
    public var autocompletionDataProviders: [TKAutocompleting] = [TKAppleGeocoder(), TKTripGoGeocoder()]
    
    /// Optional configuration of the time picker used on the routing results card.
    ///
    /// Note: this will also be re-used in the mode-by-mode card.
    public var timePickerConfig: TKUITimePickerSheet.Configuration = .default
    
    /// Set this to select which trip metrics to show for each trip group in the routing
    /// results card.
    ///
    /// It is important to note that, while you may specify a trip metric to be shown, if
    /// such metric is unavailable in the response of the routing request, it will not be
    /// shown. In addition, the order specified here is the order in which the metrics
    /// will be displayed.
    ///
    /// This setting is independent of `tripBadgesToShow`.
    ///
    /// The default metrics to show are `price`, `calories` and `carbon`.
    public var tripMetricsToShow: [TKTripCostType] = {
      var metrics: [TKTripCostType] = [.price, .calories, .carbon]
      #if DEBUG
      metrics.insert(.score, at: 0)
      #endif
      return metrics
    }()
    
    /// Set this to the allowed badges to show on a trip group.
    ///
    /// Badges will only be shown if the related scores for that metric are sufficiently different
    /// for the trips.
    ///
    /// This setting is independent of `tripMetricsToShow`.
    ///
    /// By default all badges are shown.
    public var tripBadgesToShow: Set<TKMetricClassifier.Classification> = Set(TKMetricClassifier.Classification.allCases)
    
    public var customItemProvider: TKUIRoutingResultsCustomItemProvider? = nil
    
  }

}

extension TKUIRoutingResultsCard.Configuration {
  /// Returns an adjuster that merges all backend mode identifiers whose value
  /// starts with one of the provided prefixes into a single request group per
  /// prefix.
  ///
  /// This is useful for cases where several backend modes should behave like a
  /// single logical mode in multi-fetch routing, for example school bus or DRT
  /// families discovered at runtime.
  public static func alwaysGroupModeIdentifierPrefixes(_ prefixes: [String]) -> RoutingModeRequestGroupAdjuster {
    { _, defaultGroups in
      merge(defaultGroups, byAlwaysGroupingMatchingPrefixes: prefixes)
    }
  }
  
  /// Returns an adjuster that applies multiple request-group adjusters in
  /// sequence.
  ///
  /// This lets callers compose generic grouping rules, such as always-grouped
  /// prefixes, with feature-specific rules such as injecting Park & Ride's
  /// mixed-mode request.
  public static func combineRoutingModeRequestGroupAdjusters(_ adjusters: [RoutingModeRequestGroupAdjuster]) -> RoutingModeRequestGroupAdjuster {
    { selectedModeIdentifiers, defaultGroups in
      adjusters.reduce(defaultGroups) { currentGroups, adjuster in
        adjuster(selectedModeIdentifiers, currentGroups)
      }
    }
  }
  
  fileprivate var customModeIdentifiers: Set<String> {
    Set(customModes.map(\.identifier))
  }
  
  func routingModes(in regions: [TKRegion]) -> [TKRegion.RoutingMode] {
    let regionModes = TKRegionManager.sortedModes(in: regions)
    guard !customModes.isEmpty else { return regionModes }
    
    var seen = Set(regionModes.map(\.identifier))
    let injected = customModes
      .map(\.routingMode)
      .filter { seen.insert($0.identifier).inserted }
    return regionModes + injected
  }
  
  func routingModeIdentifiers(for selectedModeIdentifiers: Set<String>) -> Set<String> {
    var adjusted = selectedModeIdentifiers
    adjusted.subtract(customModeIdentifiers)
    return adjusted
  }
  
  func routingModeRequestGroups(for selectedModeIdentifiers: Set<String>) -> Set<Set<String>> {
    let routingModeIdentifiers = routingModeIdentifiers(for: selectedModeIdentifiers)
    let defaultGroups = TKTransportMode.groupModeIdentifiers(routingModeIdentifiers, includeGroupForAll: true)
    return routingModeRequestGroupAdjuster?(selectedModeIdentifiers, defaultGroups) ?? defaultGroups
  }
  
  private static func merge(_ groups: Set<Set<String>>, byAlwaysGroupingMatchingPrefixes prefixes: [String]) -> Set<Set<String>> {
    guard !prefixes.isEmpty else { return groups }
    
    let allIdentifiers = groups.reduce(into: Set<String>()) { result, group in
      result.formUnion(group)
    }
    let allGroup = groups.first { $0 == allIdentifiers }
    
    var adjustedGroups = groups
    
    for prefix in prefixes {
      let matchedIdentifiers = adjustedGroups.reduce(into: Set<String>()) { result, group in
        result.formUnion(group.filter { $0.hasPrefix(prefix) })
      }
      guard !matchedIdentifiers.isEmpty else { continue }
      
      let groupsToAdjust = adjustedGroups.filter { group in
        group != allGroup && !group.intersection(matchedIdentifiers).isEmpty
      }
      
      guard !groupsToAdjust.isEmpty else { continue }
      
      adjustedGroups.subtract(groupsToAdjust)
      
      for group in groupsToAdjust {
        let remainingIdentifiers = group.subtracting(matchedIdentifiers)
        if !remainingIdentifiers.isEmpty {
          adjustedGroups.insert(remainingIdentifiers)
        }
      }
      
      adjustedGroups.insert(matchedIdentifiers)
    }
    
    return adjustedGroups
  }
}
