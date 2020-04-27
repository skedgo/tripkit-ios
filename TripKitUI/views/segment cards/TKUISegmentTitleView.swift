//
//  TKUISegmentTitleView
//  TripKitUI
//
//  Created by Adrian Schönig on 19.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TGCardViewController

public class TKUISegmentTitleView: UIView {

  @IBOutlet weak var modeWrapper: UIView!
  @IBOutlet weak var modeIcon: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var subsubtitleLabel: UILabel!
  
  @IBOutlet public weak var dismissButton: UIButton!
  
  var disposeBag: DisposeBag!
  
  public static func newInstance() -> TKUISegmentTitleView {
    return Bundle(for: TKUISegmentTitleView.self).loadNibNamed("TKUISegmentTitleView", owner: self, options: nil)?.first as! TKUISegmentTitleView
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    backgroundColor = .tkBackground
    
    titleLabel.font = TKUICustomization.shared.cardStyle.titleFont
    titleLabel.textColor = TKUICustomization.shared.cardStyle.titleTextColor
    titleLabel.text = nil

    subtitleLabel.font = TKUICustomization.shared.cardStyle.subtitleFont
    subtitleLabel.textColor = TKUICustomization.shared.cardStyle.subtitleTextColor
    subtitleLabel.text = nil

    subsubtitleLabel.text = nil
    
    dismissButton.setImage(TGCard.closeButtonImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
    dismissButton.accessibilityLabel = Loc.Close

    modeIcon.tintColor = .tkBackground
  }
  
  public func apply(_ style: TGCardStyle) {
    guard dismissButton != nil else { return }
    
    let styledImage = TGCard.closeButtonImage(style: style)
    dismissButton.setImage(styledImage, for: .normal)
    dismissButton.setTitle(nil, for: .normal)
  }
  
}
