//
//  TKUISectionedAlertTableHeader.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 23/3/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import UIKit

class TKUISectionedAlertTableHeader: UIView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var modeImageView: UIImageView!
  
  static func newInstance() -> TKUISectionedAlertTableHeader {
    return TripKitUIBundle.bundle().loadNibNamed("TKUISectionedAlertTableHeader", owner: self, options: nil)?.first as! TKUISectionedAlertTableHeader
  }
  
  // MARK: -
  
  override func awakeFromNib() {
    backgroundColor = TKStyleManager.backgroundColorForTileList()
    titleLabel.textColor = .white
  }
  
}
