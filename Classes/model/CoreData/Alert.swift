//
//  Alert.swift
//  Pods
//
//  Created by Kuan Lun Huang on 2/09/2016.
//
//

import Foundation

extension Alert {
  
  public var infoIconType: STKInfoIconType {
    switch alertSeverity {
    case .info, .warning: return .warning
    case .alert: return .alert
    }
  }
  
}


// MARK: - TKAlert

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
  
}


// MARK: - MKAnnotation

extension Alert: MKAnnotation {
  
  public var coordinate: CLLocationCoordinate2D {
    if let location = location {
      return location.coordinate
    } else {
      return kCLLocationCoordinate2DInvalid
    }
  }
  
}


// MARK: - STKDisplayablePoint

extension Alert: STKDisplayablePoint {
  
  public var pointDisplaysImage: Bool {
    return location != nil
  }
  
  public var pointImage: SGKImage? {
    guard let imageName = STKInfoIcon.imageName(for: infoIconType, usage: .map) else { return nil }
    return SGStyleManager.imageNamed(imageName)
  }
  
  public var pointImageURL: URL? {
    return imageURL
  }
  
  public var isDraggable: Bool {
    return false
  }
  
}
