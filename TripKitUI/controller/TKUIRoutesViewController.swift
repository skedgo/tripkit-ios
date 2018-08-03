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

    rootCard = TKUIResultsCard(destination: destination)
  }

  public init(request: TripRequest) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))

    rootCard = TKUIResultsCard(request: request)
    
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
