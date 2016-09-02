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
    return STKInfoIcon.imageForInfoIconType(infoIconType(), usage: STKInfoIconUsageNormal)
  }
  
  public var lastUpdated: NSDate? {
    return nil
  }
  
  public var sourceModel: AnyObject? {
    return self
  }
  
}