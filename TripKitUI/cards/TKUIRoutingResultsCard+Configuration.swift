//
//  TKUIRoutingResultsCard+Configuration.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension TKUIRoutingResultsCard {
  
  enum SupportType {
    /// User tried querying for a from/to pair that isn't supported yet
    case unsupportedQuery(TripRequest)
    
    /// User encountered an unidentifier routing error
    case routingError(Error, TripRequest)
  }
  
  /// Configurtion of any `TKUIRoutingResultsCard`.
  ///
  /// This isn't created directly, but rather you modify the static instance
  /// accessible from `TKUIRoutingResultsCard.config`.
  struct Configuration {
    private init() {}
    
    static let empty = Configuration()
    
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
    public var mapManagerFactory: ((MKAnnotation?) -> TKUIRoutingResultsMapManagerType) = TKUIRoutingResultsMapManager.init
    
    /// An optional list of autocompletion data providers. This list will be used by an instance of
    /// `TKUILocationSearchViewController`, which is presented when users click on
    /// the origin or destination labels. If none was provided, the `TKAppleGeocoder` and
    /// `TKSkedGoGeocoder` will be used
    public var autocompletionDataProviders: [TKAutocompleting] = [TKAppleGeocoder(), TKSkedGoGeocoder()]
  }

}
