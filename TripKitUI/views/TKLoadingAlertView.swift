//
//  TKLoadingAlertView.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 28/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKLoadingAlertView: UIView {
  
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  // MARK: - Constructor
  
  static func newInstance() -> TKLoadingAlertView {
    let bundle = TripKitUIBundle.bundle()
    return bundle.loadNibNamed("TKLoadingAlertView", owner: self, options: nil)?.first as! TKLoadingAlertView
  }

}
