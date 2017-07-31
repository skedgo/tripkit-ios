//
//  AMKLabelCell.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 15/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension AKLabelCell {
  
  public func shouldCenterTitle() -> Bool {
    return self.primaryLabel?.text != nil && self.secondaryLabel?.text == nil;
  }
  
  public func adjustLayoutForCenteredTitle() {
    self.primaryLabel?.textAlignment = shouldCenterTitle() ? .center : .left
  }
  
  open override func updateConstraints() {
    self.primaryToSecondarySpacing?.constant = self.shouldCenterTitle() ? 0.0 : 8.0
    super.updateConstraints()
  }
  
  open override func prepareForReuse() {
    super.prepareForReuse()
    
    self.primaryLabel?.textAlignment = .left
    self.primaryToSecondarySpacing?.constant = 8.0
    self.primaryLabel?.textColor = SGStyleManager.darkTextColor()
    self.secondaryLabel?.textColor = SGStyleManager.lightTextColor()
  }
  
  open override func awakeFromNib() {
    super.awakeFromNib()
    
    self.primaryLabel?.textColor = SGStyleManager.darkTextColor()
    self.secondaryLabel?.textColor = SGStyleManager.lightTextColor()
  }
  
}
