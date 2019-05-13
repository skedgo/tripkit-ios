//
//  TKModeImageBuilder.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc
@available(iOSApplicationExtension 10.0, *)
public class TKModeImageFactory: NSObject {
  
  @objc(sharedInstance)
  public static let shared = TKModeImageFactory()
  
  private let cache = NSCache<NSString, TKImage>()
  
  private override init() {
    super.init()
  }
  
  @objc(imageForModeInfo:)
  public func image(for modeInfo: TKModeInfo) -> TKImage? {
    guard let imageIdentifier = modeInfo.imageIdentifier else { return nil }
    
    if let existing = cache.object(forKey: imageIdentifier as NSString) {
      return existing
    } else {
      guard let generated = buildImage(for: modeInfo) else { return nil }
      cache.setObject(generated, forKey: imageIdentifier as NSString)
      return generated
    }
  }
  
  private func buildImage(for modeInfo: TKModeInfo) -> TKImage? {
    #if os(iOS) || os(tvOS)
    guard let overlayImage = modeInfo.image else { return nil }
    
    let newSize = CGSize(width: 19, height: 19)
    let fullRect = CGRect(origin: .zero, size: newSize)
    let renderer = UIGraphicsImageRenderer(size: newSize)
    let image = renderer.image { context in
      context.cgContext.setFillColor(#colorLiteral(red: 0.795085609, green: 0.8003450036, blue: 0.7956672311, alpha: 1))
      context.cgContext.fillEllipse(in: fullRect)
      
      context.cgContext.setStrokeColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
      context.cgContext.setLineWidth(1)
      context.cgContext.strokeEllipse(in: fullRect)
      
      context.cgContext.setFillColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
      overlayImage.draw(in: fullRect.insetBy(dx: 3, dy: 3))
    }
    return image
    
    #elseif os(OSX)
    return nil
    #endif
  }

}

fileprivate extension TKModeInfo {
  
  var imageIdentifier: String? {
    return localImageName
  }
  
}
