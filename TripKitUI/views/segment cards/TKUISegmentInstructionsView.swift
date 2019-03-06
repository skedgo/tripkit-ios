//
//  TKUISegmentInstructionsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUISegmentInstructionsView: UIView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var notesLabel: UILabel!
  
  @IBOutlet weak var accessoryStackView: UIStackView!
  
  static func newInstance() -> TKUISegmentInstructionsView {
    return Bundle.tripKitUI.loadNibNamed("TKUISegmentInstructionsView", owner: self, options: nil)?.first as! TKUISegmentInstructionsView
  }
}
