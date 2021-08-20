//
//  SecureTransformers.swift
//  TripKit
//
//  Created by Adrian Schönig on 30.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

@objc(TKColorValueTransformer)
final class TKColorValueTransformer: NSSecureUnarchiveFromDataTransformer {
  
  static let name = NSValueTransformerName(rawValue: String(describing: TKColorValueTransformer.self))
  
  override static var allowedTopLevelClasses: [AnyClass] {
    [TKColor.self]
  }
  
  static func register() {
    let transformer = TKColorValueTransformer()
    ValueTransformer.setValueTransformer(transformer, forName: name)
  }
}

@objc(TKNamedCoordinateValueTransformer)
public final class TKNamedCoordinateValueTransformer: NSSecureUnarchiveFromDataTransformer {
  
  static let name = NSValueTransformerName(rawValue: String(describing: TKNamedCoordinateValueTransformer.self))
  
  public override static var allowedTopLevelClasses: [AnyClass] {
    [TKNamedCoordinate.self, TKModeCoordinate.self, TKStopCoordinate.self]
  }
  
  public static func register() {
    let transformer = TKNamedCoordinateValueTransformer()
    ValueTransformer.setValueTransformer(transformer, forName: name)
  }
}

@objc(TKModeInfoValueTransformer)
final class TKModeInfoValueTransformer: NSSecureUnarchiveFromDataTransformer {
  
  static let name = NSValueTransformerName(rawValue: String(describing: TKModeInfoValueTransformer.self))
  
  override static var allowedTopLevelClasses: [AnyClass] {
    [TKModeInfo.self]
  }
  
  static func register() {
    let transformer = TKModeInfoValueTransformer()
    ValueTransformer.setValueTransformer(transformer, forName: name)
  }
}
