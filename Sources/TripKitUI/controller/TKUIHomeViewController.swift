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

