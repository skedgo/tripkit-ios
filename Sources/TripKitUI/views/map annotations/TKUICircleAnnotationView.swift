//
//  TKUICircleAnnotationView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 12.12.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

public protocol TKUICircleDisplayable: MKAnnotation {
  var circleColor: UIColor { get }
  var isTravelled: Bool { get }
  var asLarge: Bool { get }
}

open class TKUICircleAnnotationView: MKAnnotationView {
  private enum Constants {
    static let circleSize: CGFloat   = 12.0
    static let smallFactor: CGFloat  = 0.8
    static let lineWidth: CGFloat    = 1.5
  }
  
  public let isLarge: Bool
  
  public var circleColor: UIColor? = nil
  public var borderColor: UIColor? = nil
  public var isFaded: Bool = false
  
  public init(annotation: MKAnnotation?, drawLarge: Bool, reuseIdentifier: String?) {
    self.isLarge = drawLarge
    
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    
    let radius = Constants.circleSize * (drawLarge ? 1 : Constants.smallFactor)
    frame.size = CGSize(width: radius, height: radius)
    backgroundColor = .clear
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    
    let fillColor = self.circleColor ?? .black
    let borderColor = self.borderColor ?? fillColor.darkerColor(percentage: 0.75)
    let lineWidth = Constants.lineWidth * (isLarge ? 1 : Constants.smallFactor)
    let lineOffset = lineWidth / 2
    
    let circleRect = CGRect(x: lineOffset, y: lineOffset, width: bounds.width - lineWidth, height: bounds.height - lineWidth)
    if isFaded || circleColor != nil {
      context.setFillColor(fillColor.cgColor)
    } else {
      context.setFillColor(UIColor.tkBackgroundNotClear.cgColor)
    }
    context.fillEllipse(in: circleRect)
    
    context.setLineWidth(lineWidth)
    context.setStrokeColor(borderColor.cgColor)
    context.strokeEllipse(in: circleRect)
  }
  
}
