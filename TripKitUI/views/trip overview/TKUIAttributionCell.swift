//
//  TKUIAttributionCell.swift
//  TripKitUI
//
//  Created by Adrian Schoenig on 3/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIAttributionCell: UITableViewCell {
  
  @IBOutlet weak var titleTextView: UITextView!
  @IBOutlet weak var bodyTextView: UITextView!

  static let reuseIdentifier = "TKUIAttributionCell"
  
  static let nib = UINib(nibName: "TKUIAttributionCell", bundle: Bundle(for: TKUIAttributionCell.self))
  
  var attribution: TKAPI.DataAttribution? {
    didSet { updateUI() }
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    tintColor = .tkAppTintColor
    
    backgroundColor = .tkBackgroundTile
    
    titleTextView.font = TKStyleManager.customFont(forTextStyle: .headline)
    titleTextView.textColor = .tkLabelPrimary
    titleTextView.backgroundColor = .clear
    
    bodyTextView.font = TKStyleManager.customFont(forTextStyle: .subheadline)
    bodyTextView.textColor = .tkLabelPrimary
    bodyTextView.backgroundColor = .clear
  }
  
  private func updateUI() {
    guard let attribution = self.attribution else { return }
    titleTextView.text = attribution.provider.name    
    bodyTextView.text = attribution.disclaimer
    bodyTextView.isHidden = (attribution.disclaimer?.isEmpty ?? true)
    accessoryType = (attribution.provider.website != nil) ? .detailButton : .none
  }

}
