//
//  TKUISegmentTitleView
//  TripGoAppKit
//
//  Created by Adrian Schönig on 19.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

public class TKUISegmentTitleView: UIView {

  @IBOutlet weak var modeIcon: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var subsubtitleLabel: UILabel!
  
  @IBOutlet public weak var dismissButton: UIButton!
  
  public static func newInstance() -> TKUISegmentTitleView {
    return Bundle(for: TKUISegmentTitleView.self).loadNibNamed("TKUISegmentTitleView", owner: self, options: nil)?.first as! TKUISegmentTitleView
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    titleLabel.text = nil
    subtitleLabel.text = nil
    subsubtitleLabel.text = nil
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    
    modeIcon.tintColor = titleLabel.textColor
  }
  
}
