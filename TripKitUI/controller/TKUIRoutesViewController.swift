//
//  TKUIRoutesViewController.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 17.10.17.
//

import UIKit

import TGCardViewController

public protocol TKUIRoutesViewControllerDelegate: TGCardViewControllerDelegate {
  
}

public class TKUIRoutesViewController: TGCardViewController {
  
  public init(destination: MKAnnotation) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))

    let resultsCard = TKUIResultsCard(destination: destination)
    resultsCard.style = TKUICustomization.shared.cardStyle
    rootCard = resultsCard
  }

  public init(request: TripRequest) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))

    let resultsCard = TKUIResultsCard(request: request)
    resultsCard.style = TKUICustomization.shared.cardStyle
    rootCard = resultsCard
    
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(destination:)` or `init(request:) methods instead.")
  }
  
}
