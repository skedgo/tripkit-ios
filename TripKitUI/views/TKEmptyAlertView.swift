//
//  TKEmptyAlertView.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 3/09/2016.
//
//

import UIKit

class TKEmptyAlertView: UIView {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var footerLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    imageView.tintColor = #colorLiteral(red: 0.8549019608, green: 0.8549019608, blue: 0.8549019608, alpha: 1)
    textLabel.font = SGStyleManager.systemFont(withSize: 17)
    footerLabel.font = SGStyleManager.systemFont(withSize: 15)
  }
  
  // MARK: - Creating view
  
  class func makeView() -> TKEmptyAlertView {
    let bundle = Bundle(for: TKEmptyAlertView.self)
    return bundle.loadNibNamed(String(describing: self), owner: self, options: nil)!.first as! TKEmptyAlertView
  }
  
}
