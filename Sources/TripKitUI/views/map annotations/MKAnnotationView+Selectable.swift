//
//  MKAnnotationView+Selectable.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11/4/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import MapKit

extension MKAnnotationView {
  
  func updateSelection(for currentSelection: String?) {
    guard let displayable = annotation as? TKUISelectableOnMap else {
      alpha = 1
      isEnabled = true
      return
    }
    
    let isSelected = displayable.selectionIdentifier == currentSelection
    
    let show: Bool
    switch displayable.selectionCondition {
    case .ifSelectedOrNoSelection:
      show = isSelected || currentSelection == nil
    case .onlyIfSelected:
      show = isSelected && currentSelection != nil
    case .onlyIfSomethingElseIsSelected:
      show = !isSelected && currentSelection != nil
    }

    isEnabled = show // Don't allow selecting it, if it's hidden
    alpha = show ? 1 : 0
  }
  
}
