//
//  TKUILoadingAlertView.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 28/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

import TripKit

#if SWIFT_PACKAGE
import TripKitObjc
#endif

class TKUILoadingAlertView: UIView {
  
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  // MARK: - Constructor
  
  static func newInstance() -> TKUILoadingAlertView {
    let bundle = Bundle.tripKitUI
    let instance = bundle.loadNibNamed("TKUILoadingAlertView", owner: self, options: nil)?.first as! TKUILoadingAlertView
    instance.textLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    return instance
  }

}
