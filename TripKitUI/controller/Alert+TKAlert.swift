//
//  Alert+TKAlert.swift
//  TripKit
//
//  Created by Adrian Schönig on 12.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
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
  
  public var icon: SGKImage? {
    return STKInfoIcon.image(for: infoIconType, usage: .normal)
  }
  
  public var iconURL: URL? {
    return imageURL
  }
  
  public var lastUpdated: Date? {
    return nil
  }
  
  public func isCritical() -> Bool {
    switch alertSeverity {
    case .alert: return true
    default: return false
    }
  }
}
