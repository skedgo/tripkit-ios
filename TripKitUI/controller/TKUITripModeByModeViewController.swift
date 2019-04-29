//
//  TKUITripModeByModeViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.04.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public protocol TKUITripModeByModeViewControllerDelegate: TGCardViewControllerDelegate {
  
}

public class TKUITripModeByModeViewController: TGCardViewController {
  
  public init(trip: Trip) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    rootCard = TKUITripModeByModeCard(trip: trip)
  }
  
  public init(startingOn segment: TKSegment) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    rootCard = try! TKUITripModeByModeCard(startingOn: segment)
    
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(destination:)` or `init(request:) methods instead.")
  }
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    
    // TODO: We should make sure that the top card, still has a close button, so that you can get back to the previous screen when this is presented in an app.
  }
  
  override public func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
