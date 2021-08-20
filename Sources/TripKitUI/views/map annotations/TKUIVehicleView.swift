//
//  TKUIVehicleView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 11/5/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUIVehicleView: UIView {
  
  var color: UIColor {
    didSet {
      components = color.rgba
      setNeedsDisplay()
    }
  }
  
  private var components: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
  
  init(frame: CGRect, color: UIColor) {
    self.color = color
    self.components = color.rgba
    super.init(frame: frame)
    isOpaque = false
    backgroundColor = .clear
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    context.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 1) // white
    context.setLineWidth(2)
    context.setFillColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    
    let midmidX = rect.maxX - rect.midY
    context.move(to: .init(x: rect.minX, y: rect.minY))
    context.addLine(to: .init(x: midmidX, y: rect.minY))
    context.addLine(to: .init(x: rect.maxX, y: rect.midY))
    context.addLine(to: .init(x: midmidX, y: rect.maxY))
    context.addLine(to: .init(x: rect.minX, y: rect.maxY))
    context.addLine(to: .init(x: rect.minX, y: rect.minY))
    context.closePath()
    
    context.drawPath(using: .fillStroke)
    context.fillPath()
    context.strokePath()
  }
  
}
