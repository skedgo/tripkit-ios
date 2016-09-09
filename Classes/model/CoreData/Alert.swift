//
//  Alert.swift
//  Pods
//
//  Created by Kuan Lun Huang on 2/09/2016.
//
//

import Foundation

extension Alert: TKAlert {
  
  public var URL: String? {
    return url
  }
  
  public var icon: UIImage? {
    return STKInfoIcon.image(for: infoIconType(), usage: STKInfoIconUsageNormal)
  }
  
  public var iconURL: URL? {
    return pointImageURL()
  }
  
  public var lastUpdated: Date? {
    return nil
  }
  
}
