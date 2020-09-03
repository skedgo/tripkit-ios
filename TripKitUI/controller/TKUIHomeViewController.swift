//
//  TKUIHomeViewController.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 28/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

open class TKUIHomeViewController: TGCardViewController {
  
  public weak var searchResultsDelegate: TKUIHomeCardSearchResultsDelegate? {
    didSet {
      guard let homeCard = rootCard as? TKUIHomeCard else { return }
      homeCard.searchResultDelegate = searchResultsDelegate
    }
  }
  
  public var autocompletionDataProviders: [TKAutocompleting]?
  
  public var initialPosition: TGCardPosition?
  
  public init(initialPosition: TGCardPosition? = nil) {
    self.initialPosition = initialPosition
    
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
  }
  
  required public init?(coder: NSCoder) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
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
    
    let homeCard = TKUIHomeCard()
    homeCard.searchResultDelegate = searchResultsDelegate
    rootCard = homeCard
    
    super.viewDidLoad()
  }
  
}

