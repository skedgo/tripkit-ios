//
//  TKUISheetViewController.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.10.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

@objc
public class TKUISheetViewController: UIViewController {
  
  @objc
  public init(sheet: TKUISheet) {
    super.init(nibName: nil, bundle: nil)
    self.view = sheet
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public var sheet: TKUISheet? {
    return self.view as? TKUISheet
  }
  
  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    sheet?.doneButtonPressed(nil)
  }
  
  public override var preferredContentSize: CGSize {
    get {
      return sheet?.bounds.size ?? .zero
    }
    set {
      // do nothing
    }
  }
  
}
