//
//  AMKBaseTableViewController.swift
//  TripKit
//
//  Created by Kuan Lun Huang on 15/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension AKBaseTableViewController {
  
  public func configureTextFieldCell(_ textFieldCell: AKTextFieldCell, withItem item: AMKItem) {
    textFieldCell.configure(for: item)
  }
  
  public func configureLabelCell(_ labelCell: AKLabelCell, withItem item: AMKItem) {
    labelCell.configure(for: item)
    labelCell.accessoryType = item.isReadOnly || (item.primaryText != nil && item.secondaryText == nil) ? .none : .disclosureIndicator;
  }
  
}
