//
//  TKUIModePicker+TableViewHelper.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 03.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

extension TKUIModePicker {
  public func addAsHeader(to tableView: UITableView) {
    // constrain the picker to the width of the table view
    frame.size.width = tableView.frame.width
    
    // ask the layout system for the minimum height required to
    // display the picker in full.
    let requiredHeight = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    
    // create a wrapper that is big enough to contain the picker
    let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: requiredHeight))
    wrapper.addSubview(self)
    
    // connect up constraints
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAnchor.constraint(equalTo: wrapper.topAnchor),
      bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
      leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
      trailingAnchor.constraint(equalTo: wrapper.trailingAnchor)
    ])
    
    // attach the wrapper to the table view as table view header
    tableView.tableHeaderView = wrapper
  }
}
