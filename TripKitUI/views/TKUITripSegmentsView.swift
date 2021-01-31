//
//  TKUITripSegmentsView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUITripSegmentsView : _TKUITripSegmentsView {
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    didInit()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    didInit()
  }
  
  private func didInit() {
    darkTextColor = UIColor.tkLabelPrimary
    lightTextColor = UIColor.tkLabelSecondary
  }
  
  public override func prepare(_ imageView: UIImageView, imageURL: URL, asTemplate: Bool, placeholder: UIImage?, completion: ((Bool) -> Void)? = nil) {
    imageView.setImage(with: imageURL, asTemplate: asTemplate, placeholder: placeholder, completion: completion)
  }
  
  public override func styledLabel(withFrame frame: CGRect) -> UILabel {
    TKUIStyledLabel(frame: frame)
  }
  
  public override func realTimeAccessoryImage(animated: Bool, tintColor: UIColor) -> UIImageView {
    UIImageView(asRealTimeAccessoryImageAnimated: animated, tintColor: tintColor)
  }
  
  public override func accessibilityImageView(for displayable: TKTripSegmentDisplayable) -> UIImageView? {
    TKUISemaphoreView.accessibilityImageView(for: displayable)
  }

  
}
