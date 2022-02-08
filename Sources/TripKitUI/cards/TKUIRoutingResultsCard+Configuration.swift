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
    
    /// Set this to specify where the card should be placed when it's loaded.
    ///
    /// Defaults to `.peaking` position
    public var initialCardPosition: TGCardPosition = .peaking
    
    /// Set this to limit routing results to a certain transport modes.
    ///
    /// If this is set, the routing card will not display the Transport button,
    /// which allows users to show or hide transport modes when results are
    /// presented
    ///
    /// Defaults to nil, which means the SDK will read from `TKUserProfile`
    public var limitToModes: Set<String>? = nil
    
    /// Set this to add a button for a trip group
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
    /// `TKTripGoGeocoder` will be used
    public var autocompletionDataProviders: [TKAutocompleting] = [TKAppleGeocoder(), TKTripGoGeocoder()]
    
    /// Optional configuration of the time picker used on the routing results card
    /// Note: this will also be re-used in the mode-by-mode card
    public var timePickerConfig: TKUITimePickerSheet.Configuration = .default
    
    /// Set this to select which trip metrics to show for each trip group in the routing
    /// results card.
    ///
    /// It is important to note that, while you may specify a trip metric to be shown, if
    /// such metric is unavailable in the response of the routing request, it will not be
    /// shown. In addition, the order specified here is the order in which the metrics
    /// will be displayed.
    ///
    /// The default metrics to show are `price`, `calories` and `carbon`.
    public var tripMetricsToShow: [TKTripCostType] = {
      var metrics: [TKTripCostType] = [.price, .calories, .carbon]
      #if DEBUG
      metrics.insert(.score, at: 0)
      #endif
      return metrics
    }()
    
  }

}
