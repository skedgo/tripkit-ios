//
//  TKModeImageBuilder.swift
//  TripKit
//
//  Created by Adrian Schönig on 13.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc
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
    guard let overlayImage = modeInfo.image else { return nil }
    
#if canImport(UIKit)
    return TKImageBuilder.drawCircularImage(insideOverlay: overlayImage, background: #colorLiteral(red: 0.795085609, green: 0.8003450036, blue: 0.7956672311, alpha: 1))

#elseif os(macOS)
    return nil
#endif
  }

}

fileprivate extension TKModeInfo {
  
  var imageIdentifier: String? {
    return localImageName
  }
  
}
