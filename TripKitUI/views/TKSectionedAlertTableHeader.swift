//
//  TKSectionedAlertTableHeader.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 23/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKSectionedAlertTableHeader: UIView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var iconView: UIImageView!
  
  static func newInstance() -> TKSectionedAlertTableHeader {
    return TripKitUIBundle.bundle().loadNibNamed("TKSectionedAlertTableHeader", owner: self, options: nil)?.first as! TKSectionedAlertTableHeader
  }
  
}
