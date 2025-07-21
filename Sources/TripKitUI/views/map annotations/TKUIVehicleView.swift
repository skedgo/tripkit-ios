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

    context.setLineJoin(.round)
    context.setLineCap(.round)

    let rect = rect.insetBy(dx: 2, dy: 2)
    let radius = sqrt(CGFloat(4))
    
    // Prepare path, making it a bit less pointy
    let midmidX = rect.maxX - rect.midY
    let path = UIBezierPath()
    path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
    path.addLine(to: CGPoint(x: midmidX, y: rect.minY))
    
    // rounded tip
    path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.midY - 1))
    path.addArc(
      withCenter: CGPoint(x: rect.maxX - 4, y: rect.midY),
      radius: radius,
      startAngle: .pi * 1.75,
      endAngle: .pi * 0.25,
      clockwise: true
    )
    path.addLine(to: CGPoint(x: rect.maxX - 2, y: rect.midY + 1))
    
    // bottom right-ish
    path.addLine(to: CGPoint(x: midmidX, y: rect.maxY))
    
    // then a rounded corner at the bottom left
    path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
    path.addArc(
      withCenter: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
      radius: radius,
      startAngle: .pi * 0.5,
      endAngle: .pi,
      clockwise: true
    )
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
    
    // then a rounded corner at the top left
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
    path.addArc(
      withCenter: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
      radius: radius,
      startAngle: .pi,
      endAngle: .pi * 1.5,
      clockwise: true
    )
    path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.minY))

    path.close()

    // Fill the path
    context.setFillColor(UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a).cgColor)
    context.addPath(path.cgPath)
    context.fillPath()

    // White outline on top
    context.setLineWidth(2)
    context.setStrokeColor(UIColor.white.cgColor)
    context.addPath(path.cgPath)
    context.strokePath()
  }
  
}

