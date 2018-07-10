//
//  UIImageView+Kingfisher.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

import Kingfisher

extension UIImageView {

  @objc(setImageWithURL:)
  public func setImage(with url: URL?) {
    setImage(with: url, asTemplate: false)
  }

  @objc(setImageWithURL:asTemplate:)
  public func setImage(with url: URL?, asTemplate: Bool) {
    setImage(with: url, asTemplate: asTemplate, placeholder: nil)
  }

  @objc(setImageWithURL:placeholderImage:)
  public func setImage(with url: URL?, placeholder: TKImage?) {
    setImage(with: url, asTemplate: false, placeholder: placeholder)
  }
  
  @objc(setImageWithURL:asTemplate:placeholderImage:)
  public func setImage(with url: URL?, asTemplate: Bool, placeholder: TKImage?) {
    
    var options: KingfisherOptionsInfo = []
    if let url = url, url.path.contains("@2x") {
      options.append(.scaleFactor(2))
    } else if let url = url, url.path.contains("@3x") {
      options.append(.scaleFactor(3))
    }
    
    if asTemplate {
      options.append(.imageModifier(RenderingModeImageModifier(renderingMode: .alwaysTemplate)))
    }
    
    kf.setImage(with: url, placeholder: placeholder, options: options)
  }
  
}

extension UIButton {
  
  public func setImage(with url: URL?, for state: UIControlState) {
    setImage(with: url, for: state, placeholder: nil)
  }
  
  @objc(setImageWithURL:forState:placeholderImage:)
  public func setImage(with url: URL?, for state: UIControlState, placeholder: TKImage?) {
    
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
