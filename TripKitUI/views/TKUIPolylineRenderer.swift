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
      defaultColor: nil,
      defaultBorderColor: nil,
      selectedColor: TKStyleManager.globalTintColor(),
      selectedBorderColor: TKStyleManager.globalTintColor().darker(by: 0.5),
      deselectedColor: TKStyleManager.lightTextColor()
    )
    
    var defaultColor: UIColor?
    var defaultBorderColor: UIColor?
    var selectedColor: UIColor
    var selectedBorderColor: UIColor
    var deselectedColor: UIColor
  }
  
  /// Identifier for this polyline, used to determine selection style
  public var selectionIdentifier: String?

  /// Set this to apply custom renderer styling depending on whether it is
  /// selected.
  ///
  /// Return value should be `nil` if no selection should be applied and the
  /// default colours should be used instead.
  var selectionHandler: ((String) -> Bool?)?
  
  /// The styling to apply on selection
  var selectionStyle: SelectionStyle = .default {
    didSet {
      updateStyling()
    }
  }
  
  /// Whether it is currently styled as selected
  private var isSelected: Bool?
  
  public override init(polyline: MKPolyline) {
    super.init(polyline: polyline)
    
    lineJoin = .round
    lineCap = .square

    updateStyling()
    
    borderMultiplier = 16/12
  }
  
  override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    let oldSelection = isSelected
    if let mine = selectionIdentifier, let styler = selectionHandler {
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
    
    // Note: Do not generate new `UIColor` instances in this method, as we
    // call ith from `mapRect`, which `MKMapView` likes to hammer on many
    // background threads, which can be quite crashy. Odd.
    
    if let selected = isSelected  {
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

    } else {
      // Revert back to default style
      strokeColor = selectionStyle.defaultColor
      borderColor = selectionStyle.defaultBorderColor ?? selectionStyle.selectedBorderColor
      alpha = 1
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
