//
//  UIImageView+Kingfisher.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import UIKit

import Kingfisher

import TripKit

extension UIImageView {
  
  public static func resetCaches() {
    KingfisherManager.shared.cache.clearMemoryCache()
    KingfisherManager.shared.cache.clearDiskCache()
  }

  public func setImage(with url: URL?, asTemplate: Bool = false, placeholder: TKImage? = nil, completion: ((Bool) -> Void)? = nil) {
    
    var options: KingfisherOptionsInfo = []
    if let url = url, url.path.contains("@2x") {
      options.append(.scaleFactor(2))
    } else if let url = url, url.path.contains("@3x") {
      options.append(.scaleFactor(3))
    }
    
    if asTemplate {
      options.append(.imageModifier(RenderingModeImageModifier(renderingMode: .alwaysTemplate)))
    }
    
    kf.setImage(with: url, placeholder: placeholder, options: options, completionHandler: { result in
      switch result {
      case .success:
        completion?(true)
      case .failure:
        completion?(false)
      }
    })
  }
  
}

extension UIButton {
  
  public func setImage(with url: URL?, asTemplate: Bool = false, placeholder: TKImage? = nil, for state: UIControl.State = .normal, completion: ((Bool) -> Void)? = nil) {
    var options: KingfisherOptionsInfo = []
    if let url = url, url.path.contains("@2x") {
      options.append(.scaleFactor(2))
    } else if let url = url, url.path.contains("@3x") {
      options.append(.scaleFactor(3))
    }
    
    if asTemplate {
      options.append(.imageModifier(RenderingModeImageModifier(renderingMode: .alwaysTemplate)))
    }
    
    kf.setImage(with: url, for: state, placeholder: placeholder, options: options, completionHandler: { result in
      switch result {
      case .success:
        completion?(true)
      case .failure:
        completion?(false)
      }
    })
  }
  
}
