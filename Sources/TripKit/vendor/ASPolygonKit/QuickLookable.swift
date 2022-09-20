//
//  QuickLookable.swift
//
//  Created by Adrian Schoenig on 24/2/17.
//
//

import Foundation

#if canImport(CoreGraphics)

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(OSX)
  import Cocoa
#endif
  
extension Polygon {
  
  var quickLookPath: CGPath {
    
    let maxLength: CGFloat = 200
    let factor = maxLength / CGFloat(Double.maximum(maxX - minX, maxY - minY))
    let offset = CGPoint(x: minX, y: minY) * factor
    
    let path = CGMutablePath()
    points.enumerated().forEach { index, point in
      if index == 0 {
        path.move(to: point.cgPoint * factor - offset)
      } else {
        path.addLine(to: point.cgPoint * factor - offset, transform: .identity)
      }
    }
    path.closeSubpath()
    return path
    
  }
  
  #if os(OSX)
  var bezierPath: NSBezierPath {
    
    let maxLength: CGFloat = 200
    let factor = maxLength / CGFloat(Double.maximum(maxX - minX, maxY - minY))
    let offset = CGPoint(x: minX, y: minY) * factor
    
    let path = NSBezierPath()
    points.enumerated().forEach { index, point in
      if index == 0 {
        path.move(to: point.cgPoint * factor - offset)
      } else {
        path.line(to: point.cgPoint * factor - offset)
      }
    }
    path.close()
    return path
    
  }
  
  
  var quickLookImage: NSImage? {
    
    let path = bezierPath
    return NSImage(size: path.bounds.size, flipped: false) { rect in
      
      let strokeColor = NSColor.green
      strokeColor.setStroke()
      
      path.stroke()
      
      return true
    }
  }
  
  
  var debugQuickLookObject: Any {
    
    return quickLookImage ?? description!
    
  }

  #endif
  
}

#if os(OSX)
extension Polygon: CustomPlaygroundDisplayConvertible {
  var playgroundDescription: Any {
    return quickLookImage ?? description ?? "Undefined polygon"
  }
}
#endif


func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
  return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
  return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

extension Point {
  
  var cgPoint: CGPoint {
    return CGPoint(x: x, y: y)
  }
  
}

#endif
