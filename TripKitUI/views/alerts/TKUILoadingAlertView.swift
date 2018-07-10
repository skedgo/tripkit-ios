//
//  TKUILoadingAlertView.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 28/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKUILoadingAlertView: UIView {
  
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  // MARK: - Constructor
  
  static func newInstance() -> TKUILoadingAlertView {
    let bundle = TripKitUIBundle.bundle()
    return bundle.loadNibNamed("TKUILoadingAlertView", owner: self, options: nil)?.first as! TKUILoadingAlertView
  }

}
