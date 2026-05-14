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

  override func transformedValue(_ value: Any?) -> Any? {
    TKSecureTransformer.transform(value, allowing: Self.allowedTopLevelClasses, transformerName: "TKColorValueTransformer")
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

  public override func transformedValue(_ value: Any?) -> Any? {
    TKSecureTransformer.transform(value, allowing: Self.allowedTopLevelClasses, transformerName: "TKNamedCoordinateValueTransformer")
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

  override func transformedValue(_ value: Any?) -> Any? {
    TKSecureTransformer.transform(value, allowing: Self.allowedTopLevelClasses, transformerName: "TKModeInfoValueTransformer")
  }

  static func register() {
    let transformer = TKModeInfoValueTransformer()
    ValueTransformer.setValueTransformer(transformer, forName: name)
  }
}

/// Routes Core Data Transformable attribute decoding through `NSKeyedUnarchiver` such that any
/// decode failure surfaces as a `nil` attribute instead of an `NSInvalidUnarchiveOperationException`
/// that tears down the host process. See Redmine #25661.
enum TKSecureTransformer {
  static func transform(_ value: Any?, allowing classes: [AnyClass], transformerName: String) -> Any? {
    guard let data = value as? Data else { return nil }
    do {
      return try NSKeyedUnarchiver.unarchivedObject(ofClasses: classes, from: data)
    } catch {
      TKLog.warn(transformerName, text: "Failed to decode Core Data value, returning nil. Error: \(error)")
      return nil
    }
  }
}
