//
//  TKUIStyleKit.swift
//  TripGo
//
//  Created by Adrian Schönig on 01.08.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//
//  Generated by PaintCode
//  http://www.paintcodeapp.com
//



import UIKit

class TKUIStyleKit : NSObject {
  
  //// Drawing Methods
  

  @objc dynamic class func drawOccupancyPeople(occupied: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), occupiedCount: CGFloat = 2) {
    //// General Declarations
    let context = UIGraphicsGetCurrentContext()!
    
    
    //// Variable Declarations
    let occupiedOne: CGFloat = occupiedCount > 0 ? 0.6 : 0.12
    let occupiedTwo: CGFloat = occupiedCount > 1 ? 0.6 : 0.12
    let occupiedThree: CGFloat = occupiedCount > 2 ? 0.6 : 0.12
    let occupiedFour: CGFloat = occupiedCount > 3 ? 0.6 : 0.12
    
    //// Symbol Drawing
    context.saveGState()
    context.setAlpha(occupiedOne)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    
    let symbolRect = CGRect(x: 1, y: 4, width: 4, height: 15)
    context.saveGState()
    context.clip(to: symbolRect)
    context.translateBy(x: symbolRect.minX, y: symbolRect.minY)
    
    TKUIStyleKit.drawStandingPerson(frame: CGRect(origin: .zero, size: symbolRect.size), resizing: .stretch, occupied: occupied)
    context.restoreGState()
    
    context.endTransparencyLayer()
    context.restoreGState()
    
    
    //// Symbol 2 Drawing
    context.saveGState()
    context.setAlpha(occupiedTwo)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    
    let symbol2Rect = CGRect(x: 7, y: 4, width: 4, height: 15)
    context.saveGState()
    context.clip(to: symbol2Rect)
    context.translateBy(x: symbol2Rect.minX, y: symbol2Rect.minY)
    
    TKUIStyleKit.drawStandingPerson(frame: CGRect(origin: .zero, size: symbol2Rect.size), resizing: .stretch, occupied: occupied)
    context.restoreGState()
    
    context.endTransparencyLayer()
    context.restoreGState()
    
    
    //// Symbol 3 Drawing
    context.saveGState()
    context.setAlpha(occupiedThree)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    
    let symbol3Rect = CGRect(x: 13, y: 4, width: 4, height: 15)
    context.saveGState()
    context.clip(to: symbol3Rect)
    context.translateBy(x: symbol3Rect.minX, y: symbol3Rect.minY)
    
    TKUIStyleKit.drawStandingPerson(frame: CGRect(origin: .zero, size: symbol3Rect.size), resizing: .stretch, occupied: occupied)
    context.restoreGState()
    
    context.endTransparencyLayer()
    context.restoreGState()
    
    
    //// Symbol 4 Drawing
    context.saveGState()
    context.setAlpha(occupiedFour)
    context.beginTransparencyLayer(auxiliaryInfo: nil)
    
    let symbol4Rect = CGRect(x: 19, y: 4, width: 4, height: 15)
    context.saveGState()
    context.clip(to: symbol4Rect)
    context.translateBy(x: symbol4Rect.minX, y: symbol4Rect.minY)
    
    TKUIStyleKit.drawStandingPerson(frame: CGRect(origin: .zero, size: symbol4Rect.size), resizing: .stretch, occupied: occupied)
    context.restoreGState()
    
    context.endTransparencyLayer()
    context.restoreGState()
  }
  
  @objc dynamic class func drawStandingPerson(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 4, height: 15), resizing: ResizingBehavior = .aspectFit, occupied: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000)) {
    //// General Declarations
    let context = UIGraphicsGetCurrentContext()!
    
    //// Resize to Target Frame
    context.saveGState()
    let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 4, height: 15), target: targetFrame)
    context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
    context.scaleBy(x: resizedFrame.width / 4, y: resizedFrame.height / 15)
    
    
    //// Bezier Drawing
    let bezierPath = UIBezierPath()
    bezierPath.move(to: CGPoint(x: 3, y: 10))
    bezierPath.addLine(to: CGPoint(x: 3, y: 14))
    bezierPath.addCurve(to: CGPoint(x: 2, y: 15), controlPoint1: CGPoint(x: 3, y: 14.55), controlPoint2: CGPoint(x: 2.55, y: 15))
    bezierPath.addCurve(to: CGPoint(x: 1, y: 14), controlPoint1: CGPoint(x: 1.45, y: 15), controlPoint2: CGPoint(x: 1, y: 14.55))
    bezierPath.addLine(to: CGPoint(x: 1, y: 10))
    bezierPath.addCurve(to: CGPoint(x: 0, y: 9), controlPoint1: CGPoint(x: 0.45, y: 10), controlPoint2: CGPoint(x: 0, y: 9.55))
    bezierPath.addLine(to: CGPoint(x: 0, y: 5))
    bezierPath.addCurve(to: CGPoint(x: 1, y: 4), controlPoint1: CGPoint(x: 0, y: 4.45), controlPoint2: CGPoint(x: 0.45, y: 4))
    bezierPath.addLine(to: CGPoint(x: 3, y: 4))
    bezierPath.addCurve(to: CGPoint(x: 4, y: 5), controlPoint1: CGPoint(x: 3.55, y: 4), controlPoint2: CGPoint(x: 4, y: 4.45))
    bezierPath.addLine(to: CGPoint(x: 4, y: 9))
    bezierPath.addCurve(to: CGPoint(x: 3, y: 10), controlPoint1: CGPoint(x: 4, y: 9.55), controlPoint2: CGPoint(x: 3.55, y: 10))
    bezierPath.close()
    bezierPath.move(to: CGPoint(x: 2, y: 3))
    bezierPath.addCurve(to: CGPoint(x: 0.5, y: 1.5), controlPoint1: CGPoint(x: 1.17, y: 3), controlPoint2: CGPoint(x: 0.5, y: 2.33))
    bezierPath.addCurve(to: CGPoint(x: 2, y: 0), controlPoint1: CGPoint(x: 0.5, y: 0.67), controlPoint2: CGPoint(x: 1.17, y: 0))
    bezierPath.addCurve(to: CGPoint(x: 3.5, y: 1.5), controlPoint1: CGPoint(x: 2.83, y: 0), controlPoint2: CGPoint(x: 3.5, y: 0.67))
    bezierPath.addCurve(to: CGPoint(x: 2, y: 3), controlPoint1: CGPoint(x: 3.5, y: 2.33), controlPoint2: CGPoint(x: 2.83, y: 3))
    bezierPath.close()
    bezierPath.usesEvenOddFillRule = true
    occupied.setFill()
    bezierPath.fill()
    
    context.restoreGState()
    
  }
  
  //// Generated Images
  
  @objc dynamic class func imageOfOccupancyPeople(occupied: UIColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1.000), occupiedCount: CGFloat = 2) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 24, height: 24), false, 0)
    TKUIStyleKit.drawOccupancyPeople(occupied: occupied, occupiedCount: occupiedCount)
    
    let imageOfOccupancyPeople = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return imageOfOccupancyPeople
  }
  
  
  
  
  @objc(TKUIStyleKitResizingBehavior)
  enum ResizingBehavior: Int {
    case aspectFit /// The content is proportionally resized to fit into the target rectangle.
    case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
    case stretch /// The content is stretched to match the entire target rectangle.
    case center /// The content is centered in the target rectangle, but it is NOT resized.
    
    func apply(rect: CGRect, target: CGRect) -> CGRect {
      if rect == target || target == CGRect.zero {
        return rect
      }
      
      var scales = CGSize.zero
      scales.width = abs(target.width / rect.width)
      scales.height = abs(target.height / rect.height)
      
      switch self {
      case .aspectFit:
        scales.width = min(scales.width, scales.height)
        scales.height = scales.width
      case .aspectFill:
        scales.width = max(scales.width, scales.height)
        scales.height = scales.width
      case .stretch:
        break
      case .center:
        scales.width = 1
        scales.height = 1
      }
      
      var result = rect.standardized
      result.size.width *= scales.width
      result.size.height *= scales.height
      result.origin.x = target.minX + (target.width - result.width) / 2
      result.origin.y = target.minY + (target.height - result.height) / 2
      return result
    }
  }
}
