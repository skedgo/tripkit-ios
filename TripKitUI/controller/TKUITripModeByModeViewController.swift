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
  
  public init(trip: Trip, initialPosition: TGCardPosition = .peaking) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let mxmCard = TKUITripModeByModeCard(trip: trip, initialPosition: initialPosition)
    mxmCard.style = TKUICustomization.shared.cardStyle
    mxmCard.modeByModeDelegate = self
    rootCard = mxmCard
  }
  
  public init(startingOn segment: TKSegment, mode: TKUISegmentMode = .onSegment, initialPosition: TGCardPosition = .peaking) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let mxmCard = try! TKUITripModeByModeCard(startingOn: segment, mode: mode, initialPosition: initialPosition)
    mxmCard.style = TKUICustomization.shared.cardStyle
    mxmCard.modeByModeDelegate = self
    rootCard = mxmCard
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(trip:)` or `init(startingOn:) methods instead.")
  }
  
}

extension TKUITripModeByModeViewController: TKUITripModeByModeCardDelegate {
  public func modeByModeRequestsRebuildForNewSegments(_ card: TKUITripModeByModeCard, trip: Trip, currentSegment: TKSegment) {
    do {
      let newCard = try TKUITripModeByModeCard(startingOn: currentSegment)
      newCard.style = TKUICustomization.shared.cardStyle
      newCard.modeByModeDelegate = self
      self.swap(for: newCard, animated: true)
    
    } catch {
      TKUICustomization.shared.alertHandler(error, self)
    }
  }
}
