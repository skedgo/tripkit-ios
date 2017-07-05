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
  public func kf_setImage(with url: URL) {
    kf.setImage(with: url)
  }

  @objc(setImageWithURL:placeholderImage:)
  public func kf_setImage(with url: URL, placeholder: SGKImage) {
    kf.setImage(with: url, placeholder: placeholder)
  }
  
  
}
