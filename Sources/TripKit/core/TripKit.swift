//
//  TripKit.swift
//  TripKit
//
//  Created by Adrian Schoenig on 6/4/17.
//
//

import Foundation
import CoreData

#if SWIFT_PACKAGE
@_exported import TripKitObjc
#endif

public enum TripKit {
  
  public static let shared = TKTripKit.__sharedInstance()
  
  public static func loadModel() -> NSManagedObjectModel {
    let bundle = Bundle(for: TKTripKit.self)
    let modelURL = bundle.url(forResource: "TripKitModel", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
  }
  
  public static var apiKey: String {
    get {
      return TKServer.shared.apiKey
    }
    set {
      TKServer.shared.apiKey = newValue
    }
  }
  
  /// Prepares TripKit to be used
  ///
  /// Should be called from the application delegate, typically from
  /// `application:didFinishLaunchingWithOptions` and
  /// `applicationWillEnterForeground`.
  public static func prepareForNewSession() {
    
    // Backwards compatibility with old versions of TripKit
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "TripKit.TKNamedCoordinate")
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "TripKit.SGKNamedCoordinate")
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "SGCoreKit.SGKNamedCoordinate")
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "TKNamedCoordinate")
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "SGKNamedCoordinate")
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "SGNamedCoordinate")
    NSKeyedUnarchiver.setClass(TKNamedCoordinate.self, forClassName: "NamedCoordinate")

    NSKeyedUnarchiver.setClass(TKModeCoordinate.self, forClassName: "TripKit.TKModeCoordinate")
    NSKeyedUnarchiver.setClass(TKModeCoordinate.self, forClassName: "TripKit.STKModeCoordinate")
    NSKeyedUnarchiver.setClass(TKModeCoordinate.self, forClassName: "TKModeCoordinate")
    NSKeyedUnarchiver.setClass(TKModeCoordinate.self, forClassName: "STKModeCoordinate")

    NSKeyedUnarchiver.setClass(TKMiniInstruction.self, forClassName: "TripKit.TKMiniInstruction")
    NSKeyedUnarchiver.setClass(TKMiniInstruction.self, forClassName: "TripKit.STKMiniInstruction")
    NSKeyedUnarchiver.setClass(TKMiniInstruction.self, forClassName: "TKMiniInstruction")
    NSKeyedUnarchiver.setClass(TKMiniInstruction.self, forClassName: "STKMiniInstruction")
    
    NSKeyedUnarchiver.setClass(TKStopCoordinate.self, forClassName: "TripKit.TKStopCoordinate")
    NSKeyedUnarchiver.setClass(TKStopCoordinate.self, forClassName: "TripKit.STKStopCoordinate")
    NSKeyedUnarchiver.setClass(TKStopCoordinate.self, forClassName: "SGCoreKit.STKStopCoordinate")
    NSKeyedUnarchiver.setClass(TKStopCoordinate.self, forClassName: "TKStopCoordinate")
    NSKeyedUnarchiver.setClass(TKStopCoordinate.self, forClassName: "STKStopCoordinate")
    NSKeyedUnarchiver.setClass(TKStopCoordinate.self, forClassName: "SGStopCoordinate")

    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "TripKit.TKRegion")
    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "TripKit.SVKRegion")
    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "SGCoreKit.SVKRegion")
    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "TKRegion")
    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "SVKRegion")
    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "SGRegion")
    NSKeyedUnarchiver.setClass(TKRegion.self, forClassName: "Region")

    NSKeyedUnarchiver.setClass(TKModeInfo.self, forClassName: "TripKit.TKModeInfo")
    NSKeyedUnarchiver.setClass(TKModeInfo.self, forClassName: "TripKit.ModeInfo")
    NSKeyedUnarchiver.setClass(TKModeInfo.self, forClassName: "SGCoreKit.ModeInfo")
    NSKeyedUnarchiver.setClass(TKModeInfo.self, forClassName: "TKModeInfo")
    NSKeyedUnarchiver.setClass(TKModeInfo.self, forClassName: "ModeInfo")
    
    // Give the main class a nudge to wake up
    let _ = TripKit.shared
    
    TKRegionManager.shared.updateRegions()
  }
  
}

extension TKTripKit {
  @objc
  public static func prepareForNewSession() {
    TripKit.prepareForNewSession()
  }
  
  @objc
  public static func setAPIKey(_ key: String) {
    TripKit.apiKey = key
  }
}
