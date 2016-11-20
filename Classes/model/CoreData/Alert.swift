//
//  Alert.swift
//  Pods
//
//  Created by Kuan Lun Huang on 2/09/2016.
//
//

import Foundation

extension Alert: TKAlert {
  
  public var infoURL: URL? {
    if let url = url {
      return URL(string: url)
    } else {
      return nil
    }
  }
  
  public var icon: UIImage? {
    return STKInfoIcon.image(for: infoIconType(), usage: .normal)
  }
  
  public var iconURL: URL? {
    return imageURL
  }
  
  public var lastUpdated: Date? {
    return nil
  }
  
}
