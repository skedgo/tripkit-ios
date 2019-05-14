//
//  UIImageView+Kingfisher.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import Kingfisher

import TripKit

extension UIImageView {

  @objc(setImageWithURL:)
  public func _setImage(with url: URL?) {
    setImage(with: url)
  }

  @objc(setImageWithURL:asTemplate:)
  public func _setImage(with url: URL?, asTemplate: Bool) {
    setImage(with: url, asTemplate: asTemplate)
  }

  @objc(setImageWithURL:placeholderImage:)
  public func _setImage(with url: URL?, placeholder: TKImage?) {
    setImage(with: url, placeholder: placeholder)
  }
  
  @objc(setImageWithURL:asTemplate:placeholderImage:)
  public func _setImage(with url: URL?, asTemplate: Bool, placeholder: TKImage?) {
    setImage(with: url, asTemplate: asTemplate, placeholder: placeholder)
  }
  
  @objc(setImageWithURL:asTemplate:placeholderImage:completionHandler:)
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
    
    kf.setImage(with: url, placeholder: placeholder, options: options) { result in
      switch result {
      case .success:
        completion?(true)
      case .failure:
        completion?(false)
      }
    }
  }
  
}

extension UIButton {
  
  public func setImage(with url: URL?, for state: UIControl.State) {
    setImage(with: url, for: state, placeholder: nil)
  }
  
  @objc(setImageWithURL:forState:placeholderImage:)
  public func setImage(with url: URL?, for state: UIControl.State, placeholder: TKImage?) {
    
    let options: KingfisherOptionsInfo?
    if let url = url, url.path.contains("@2x") {
      options = [.scaleFactor(2)]
    } else if let url = url, url.path.contains("@3x") {
      options = [.scaleFactor(3)]
    } else {
      options = nil
    }
    
    kf.setImage(with: url, for: state, placeholder: placeholder, options: options)
  }
  
}
