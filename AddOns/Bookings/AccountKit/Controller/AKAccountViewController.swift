//
//  AMKSimpleAccountViewController.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 15/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public extension AKAccountViewController {
  
  override public func configureLabelCell(_ labelCell: AKLabelCell, withItem item: AMKItem) {
    super.configureLabelCell(labelCell, withItem: item)
    
    if item.actionType == .destructive {
      labelCell.primaryLabel?.textColor = UIColor.red
    }
  }
  
}
