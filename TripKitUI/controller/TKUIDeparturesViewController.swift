//
//  TKUIDeparturesViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 24.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

public protocol TKUIDeparturesViewControllerDelegate: TGCardViewControllerDelegate {
  
}

public class TKUIDeparturesViewController: TGCardViewController {
  
  public init(stops: [TKUIStopAnnotation]) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let departuresCard = TKUIDeparturesCard(stops: stops)
    departuresCard.style = TKUICustomization.shared.cardStyle
    rootCard = departuresCard
  }
  
  public init(dlsTable: TKDLSTable, startDate: Date) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
    
    let departuresCard = TKUIDeparturesCard(dlsTable: dlsTable, startDate: startDate)
    departuresCard.style = TKUICustomization.shared.cardStyle
    rootCard = departuresCard
    
  }
  
  required public init(coder aDecoder: NSCoder) {
    fatalError("Use the `init(stops:)` or `init(dlsTable:startDate:) methods instead.")
  }
  
}
