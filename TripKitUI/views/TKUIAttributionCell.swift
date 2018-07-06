//
//  TKUIAttributionCell.swift
//  TripGo
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
  
  func configure(for attribution: API.DataAttribution) {
    titleTextView.text = attribution.provider.name
    
    bodyTextView.text = attribution.disclaimer
    bodyTextView.isHidden = (attribution.disclaimer == nil)
  }

}
