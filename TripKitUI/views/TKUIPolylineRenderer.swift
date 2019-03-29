//
//  TKUIPolylineRenderer.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import ASPolylineView

open class TKUIPolylineRenderer: ASPolylineRenderer {
  
  struct SelectionStyle {
    static let `default` = SelectionStyle(
      selectedColor: TKStyleManager.globalTintColor(),
      selectedBorderColor: TKStyleManager.globalTintColor().darker(by: 0.5),
      deselectedColor: TKStyleManager.lightTextColor()
    )
    
    let selectedColor: UIColor
    let selectedBorderColor: UIColor
    let deselectedColor: UIColor
  }
  
  /// Identifier for this polyline, used to determine selection style
  public var selectionIdentifier: String?

  /// Set this to apply custom renderer styling depending on whether it is
  /// selected.
  ///
  /// Return value should be `nil` if no selection should be applied and the
  /// default colours should be used instead.
  var selectionStyler: ((String) -> Bool?)?
  
  /// The styling to apply on selection
  var selectionStyle: SelectionStyle = .default
  
  /// Whether it is currently styled as selected
  private var isSelected: Bool?
  
  public override init(polyline: MKPolyline) {
    super.init(polyline: polyline)
    
    lineWidth = 12
    lineJoin = .round
    lineCap = .square
    alpha = 1.0
    
    borderMultiplier = 16/12
  }
  
  override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    let oldSelection = isSelected
    if let mine = selectionIdentifier, let styler = selectionStyler {
      isSelected = styler(mine)
    } else {
      isSelected = nil
    }
    if oldSelection != isSelected {
      updateStyling()
    }
    
    super.draw(mapRect, zoomScale: zoomScale, in: context)
  }
  
  private func updateStyling() {
    // TODO: Revert to default style
    guard let selected = isSelected else { return }

    if selected {
      strokeColor = selectionStyle.selectedColor
      borderColor = selectionStyle.selectedBorderColor
      alpha = 1
      lineWidth = 24
    } else {
      strokeColor = selectionStyle.deselectedColor
      borderColor = selectionStyle.deselectedColor
      alpha = 0.3
      lineWidth = 12
    }
  }
  
}

extension UIColor {
  func darker(by percentage: CGFloat) -> UIColor {
    guard let components = cgColor.components else { return self }
    
    let multiplier = 1 - percentage
    if components.count == 2 {
      return UIColor(white: multiplier * components[0], alpha: components[1])
    } else if components.count == 4 {
      return UIColor(
        red: components[0] * multiplier,
        green: components[1] * multiplier,
        blue: components[2] * multiplier,
        alpha: components[3])
    } else {
      return self
    }
  }
}
