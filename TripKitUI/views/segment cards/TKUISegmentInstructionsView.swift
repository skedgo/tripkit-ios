//
//  TKUISegmentInstructionsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

/// View for detailed instructions of a segment as part of a
/// `TGUISegmentInstructionCard`.
///
/// - Note: Does not include title, which is meant to go into the card's title
///     view.
class TKUISegmentInstructionsView: UIView {
  
  @IBOutlet weak var notesLabel: UILabel!
  
  @IBOutlet weak var accessoryStackView: UIStackView!
  
  static func newInstance() -> TKUISegmentInstructionsView {
    return Bundle.tripKitUI.loadNibNamed("TKUISegmentInstructionsView", owner: self, options: nil)?.first as! TKUISegmentInstructionsView
  }
}
