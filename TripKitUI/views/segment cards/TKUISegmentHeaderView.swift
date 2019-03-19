//
//  TKUISegmentHeaderView
//  TripGoAppKit
//
//  Created by Adrian Schönig on 19.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxSwift

import TGCardViewController

public class TKUISegmentHeaderView: UIView {

  @IBOutlet weak var modeIcon: UIImageView!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var subsubtitleLabel: UILabel!
  
  @IBOutlet public weak var dismissButton: UIButton!
  
  private let disposeBag = DisposeBag()
  
  public static func newInstance() -> TKUISegmentHeaderView {
    return Bundle(for: TKUISegmentHeaderView.self).loadNibNamed("TKUISegmentHeaderView", owner: self, options: nil)?.first as! TKUISegmentHeaderView
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
  
  public func configure(for segment: TKTripSegment) {
    titleLabel.text = segment.tripSegmentInstruction
    subtitleLabel.text = segment.tripSegmentDetail
    
    modeIcon.setImage(with: segment.tripSegmentModeImageURL, asTemplate: segment.tripSegmentModeImageIsTemplate, placeholder: segment.tripSegmentModeImage)
  }
  
}
