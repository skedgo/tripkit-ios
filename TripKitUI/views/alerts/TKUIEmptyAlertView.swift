//
//  TKUIEmptyAlertView.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 3/09/2016.
//
//

import UIKit

class TKUIEmptyAlertView: UIView {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var footerLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    imageView.tintColor = #colorLiteral(red: 0.8549019608, green: 0.8549019608, blue: 0.8549019608, alpha: 1)
    textLabel.font = TKStyleManager.customFont(forTextStyle: .body)
    footerLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
  }
  
  // MARK: - Creating view
  
  static func makeView() -> TKUIEmptyAlertView {
    let bundle = TripKitUIBundle.bundle()
    return bundle.loadNibNamed(String(describing: self), owner: self, options: nil)!.first as! TKUIEmptyAlertView
  }
  
}
