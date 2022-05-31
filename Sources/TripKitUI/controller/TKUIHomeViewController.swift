//
//  TKUIHomeViewController.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 28/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

import TripKit


/// The `TKUIHomeViewController` class provides a customisable user interface of a
/// search bar, a map, and a list of *components*.
///
/// ## How to use
///
/// You will need to provide a list of components that specify the content of the home card. You do
/// so by providing a list of classes that implement ``TKUIHomeComponentViewModel``:
///
/// ```swift
/// TKUIHomeCard.config.componentViewModelClasses = [
///   MyFavoritesViewModel.self,
///   MySearchHistoryViewModel.self
/// ]
/// ```
///
/// ## Notes on subclassing
///
/// This class is safe to subclass, but you need to pay attention to the order of things in your
/// `viewDidLoad` method:
///
/// ```swift
/// override func viewDidLoad() {
///    self.autocompletionDataProviders = /* add your data sources here */
///
///    super.viewDidLoad()
///
///    // other customisation
/// }
/// ```
///
open class TKUIHomeViewController: TGCardViewController {
  
  public weak var searchResultsDelegate: TKUIHomeCardSearchResultsDelegate? {
    didSet {
      guard let homeCard = rootCard as? TKUIHomeCard else { return }
      homeCard.searchResultDelegate = searchResultsDelegate
    }
  }
  
  public var autocompletionDataProviders: [TKAutocompleting]?
  
  public var initialPosition: TGCardPosition?
  
  public var mapManager: TKUICompatibleHomeMapManager?
  
  public init(mapManager: TKUICompatibleHomeMapManager? = nil, initialPosition: TGCardPosition? = nil) {
    self.initialPosition = initialPosition
    self.mapManager = mapManager
    
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
  }
  
  required public init?(coder: NSCoder) {
    super.init(nibName: "TGCardViewController", bundle: TGCardViewController.bundle)
  }
  
  open override func viewDidLoad() {
    
    // Here, we always route from user's current location, hence
    // make sure we ask for permission.
    builder.askForLocationPermissions = { completion in
      TKLocationManager.shared.ask(forPermission: completion)
    }
    
    // We can also select a different place for the current location
    // button
    locationButtonPosition = .bottom
    
    TKUIHomeCard.config.autocompletionDataProviders = autocompletionDataProviders
    
    let homeCard = TKUIHomeCard(mapManager: mapManager, initialPosition: initialPosition)
    homeCard.style = TKUICustomization.shared.cardStyle
    homeCard.searchResultDelegate = searchResultsDelegate
    rootCard = homeCard

    super.viewDidLoad()
  }
  
}

