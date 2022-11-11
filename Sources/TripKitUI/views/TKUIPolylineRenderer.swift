//
//  TKUIPolylineRenderer.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 29.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import CoreGraphics
import MapKit

import TripKit

open class TKUIPolylineRenderer: MKPolylineRenderer {
  
  public enum SelectionMode {
    case thickWithSelectionColor
    case regularWithNormalColor
  }

  struct SelectionStyle {
    static let `default` = SelectionStyle(
      defaultColor: nil,
      defaultBorderColor: nil,
      selectedColor: TKStyleManager.globalTintColor,
      selectedBorderColor: TKStyleManager.globalTintColor.darker(by: 0.5),
      deselectedColor: .tkLabelSecondary
    )
    
    var defaultColor: UIColor?
    var defaultBorderColor: UIColor?
    var selectedColor: UIColor
    var selectedBorderColor: UIColor
    var deselectedColor: UIColor
  }
  
  /// Whether there should be a background behind dashes
  public var fillDashBackground: Bool = true
  
  /// Color used for the wider border around the polyline.
  /// Defaults to black.
  public var borderColor: UIColor = .tkLabelPrimary
  
  /// Color used as the backdrop if there's a dash pattern
  /// Defaults to white
  public var backgroundColor: UIColor? = .tkBackground
  
  /// The factor by which the border expands past the line.
  /// 1.5 leads to a very thin line.
  /// Defaults to 2.0
  public var borderMultiplier: CGFloat = 2.0
  
  /// Identifier for this polyline, used to determine selection style
  public var selectionIdentifier: String?

  /// Set this to apply custom renderer styling depending on whether it is
  /// selected.
  ///
  /// Return value should be `nil` if no selection should be applied and the
  /// default colours should be used instead.
  var selectionHandler: ((String) -> Bool?)?
  
  /// The styling to apply on selection
  var selectionStyle: SelectionStyle {
    didSet {
      updateStyling()
    }
  }
  
  var selectionMode: SelectionMode = .thickWithSelectionColor
  
  /// Whether it is currently styled as selected
  private var isSelected: Bool?
  
  public override init(polyline: MKPolyline) {
    selectionStyle = .default
    
    super.init(overlay: polyline)
    
    lineJoin = .round
    lineCap = .square

    updateStyling()
    
    borderMultiplier = 16/12
  }
  
  private func drawLine(color: CGColor, width: CGFloat, allowDashes: Bool, zoomScale: MKZoomScale, in context: CGContext) {
    guard let path = path else { return }
    
    if allowDashes {
      // Defaults take care of dash pattern
      applyStrokeProperties(to: context, atZoomScale: zoomScale)
    } else {
      context.setLineCap(lineCap)
      context.setLineJoin(lineJoin)
      context.setMiterLimit(miterLimit)
    }
    
    context.setStrokeColor(color)
    context.setLineWidth(width / zoomScale)

    // Don't use `strokePath(path, in: context)`, as that doesn't always stroke (?)
    context.addPath(path)
    context.strokePath()
  }
  
  override open func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
    guard path != nil else { return }

    let oldSelection = isSelected
    if let mine = selectionIdentifier, let styler = selectionHandler {
      isSelected = styler(mine)
    } else {
      isSelected = nil
    }
    if oldSelection != isSelected {
      updateStyling()
    }
    
    let baseWidth = self.lineWidth
    let width = zoomScale < 0.01 ? baseWidth / 2 : baseWidth
    let includeBackground = lineDashPattern == nil || fillDashBackground
    
    // draw the border, it's slightly wider than the specified width
    drawLine(color: borderColor.cgColor, width: width * borderMultiplier, allowDashes: !includeBackground, zoomScale: zoomScale, in: context)
    
    // background onto which to draw dashes
    if includeBackground, let background = backgroundColor {
      drawLine(color: background.cgColor, width: width, allowDashes: false, zoomScale: zoomScale, in: context)
    }
    
    // the regular line
    if let stroke = strokeColor {
      drawLine(color: stroke.cgColor, width: width, allowDashes: true, zoomScale: zoomScale, in: context)
    }
  }
  
  private func updateStyling() {
    
    // Note: Do not generate new `UIColor` instances in this method, as we
    // call ith from `mapRect`, which `MKMapView` likes to hammer on many
    // background threads, which can be quite crashy. Odd.
    
    if let selected = isSelected  {
      if selected {
        switch selectionMode {
        case .regularWithNormalColor:
          strokeColor = selectionStyle.defaultColor
          borderColor = selectionStyle.defaultBorderColor ?? selectionStyle.selectedBorderColor
          lineWidth = 12
        case .thickWithSelectionColor:
          strokeColor = selectionStyle.selectedColor
          borderColor = selectionStyle.selectedBorderColor
          lineWidth = 24
        }
        alpha = 1

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
