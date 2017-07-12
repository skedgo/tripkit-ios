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
  public func kf_setImage(with url: URL?) {
    kf_setImage(with: url, placeholder: nil)
  }

  @objc(setImageWithURL:placeholderImage:)
  public func kf_setImage(with url: URL?, placeholder: SGKImage?) {
    
    let options: KingfisherOptionsInfo?
    if let url = url, url.path.contains("@2x") {
      options = [.scaleFactor(2)]
    } else if let url = url, url.path.contains("@3x") {
      options = [.scaleFactor(3)]
    } else {
      options = nil
    }
    
    kf.setImage(with: url, placeholder: placeholder, options: options)
  }
  
}
