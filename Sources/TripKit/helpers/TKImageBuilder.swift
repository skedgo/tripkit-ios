//
//  TKImageBuilder.swift
//  TripKit
//
//  Created by Adrian Schönig on 20.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit

class TKImageBuilder {
  
  /// Creates a circular image that is a small version of the provided image
  /// clipped to be a circle with a white outline. Similar style to macOS user
  /// images in tiny.
  ///
  /// - Parameter insideImage: Image to be clipped
  /// - Returns: New image
  static func drawCircularImage(insideImage: TKImage) -> TKImage {
    let newSize = CGSize(width: 19, height: 19)
    let fullRect = CGRect(origin: .zero, size: newSize)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    let image = renderer.image { context in
      context.cgContext.beginPath()
      context.cgContext.addEllipse(in: fullRect)
      context.cgContext.clip()
      
      insideImage.draw(in: fullRect)
      
      context.cgContext.resetClip()
      
      context.cgContext.setStrokeColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
      context.cgContext.setLineWidth(1)
      context.cgContext.strokeEllipse(in: fullRect)
    }
    return image
  }
  
  /// Creates a circular image that has a white outline and the provided
  /// background colour with the provided image drawn in white on top.
  ///
  /// - Parameters:
  ///   - insideOverlay: Inside image, should be a template as it will be drawn
  ///       all white.
  ///   - background: Background colour for the circle
  /// - Returns: New image
  static func drawCircularImage(insideOverlay: TKImage, background: CGColor) -> TKImage {
    let newSize = CGSize(width: 19, height: 19)
    let fullRect = CGRect(origin: .zero, size: newSize)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    let image = renderer.image { context in
      context.cgContext.setFillColor(background)
      context.cgContext.fillEllipse(in: fullRect)
      
      context.cgContext.setStrokeColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
      context.cgContext.setLineWidth(1)
      context.cgContext.strokeEllipse(in: fullRect)
      
      context.cgContext.setFillColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
      insideOverlay.draw(in: fullRect.insetBy(dx: 3, dy: 3))
    }
    return image
  }
  
}
#endif
