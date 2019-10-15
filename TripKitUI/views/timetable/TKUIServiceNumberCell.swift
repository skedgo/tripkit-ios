//
//  TKUIServiceNumberCell.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 10.09.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIServiceNumberCell: UICollectionViewCell {

  static let reuseIdentifier: String = "TKUIServiceNumberCell"
  
  static let nib = UINib(nibName: "TKUIServiceNumberCell", bundle: Bundle(for: TKUIServiceNumberCell.self))
  
  static func newInstance() -> TKUIServiceNumberCell {
    return Bundle(for: self).loadNibNamed("TKUIServiceNumberCell", owner: self, options: nil)?.first as! TKUIServiceNumberCell
  }

  @IBOutlet weak var wrapperView: UIView!
  @IBOutlet weak var numberLabel: TKUIStyledLabel!

}
