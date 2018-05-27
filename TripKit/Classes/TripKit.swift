//
//  TripKit.swift
//  TripKit
//
//  Created by Adrian Schoenig on 6/4/17.
//
//

import Foundation

public enum TripKit {
  
  public static let shared = TKTripKit.__sharedInstance()
  
  public static var apiKey: String {
    get {
      return SVKServer.shared.apiKey
    }
    set {
      SVKServer.shared.apiKey = newValue
    }
  }
  
  
  /// Prepares TripKit to be used
  ///
  /// Should be called from the application delegate, typically from
  /// `application:didFinishLaunchingWithOptions` and
  /// `applicationWillEnterForeground`.
  public static func prepareForNewSession() {
    
    // Backwards compatibility with old versions of TripKit
    NSKeyedUnarchiver.setClass(SGKNamedCoordinate.self, forClassName: "TripKit.SGKNamedCoordinate")
    NSKeyedUnarchiver.setClass(SGKNamedCoordinate.self, forClassName: "SGCoreKit.SGKNamedCoordinate")
    NSKeyedUnarchiver.setClass(SGKNamedCoordinate.self, forClassName: "SGKNamedCoordinate")
    NSKeyedUnarchiver.setClass(SGKNamedCoordinate.self, forClassName: "SGNamedCoordinate")
    NSKeyedUnarchiver.setClass(SGKNamedCoordinate.self, forClassName: "NamedCoordinate")
    
    NSKeyedUnarchiver.setClass(STKStopCoordinate.self, forClassName: "TripKit.STKStopCoordinate")
    NSKeyedUnarchiver.setClass(STKStopCoordinate.self, forClassName: "SGCoreKit.STKStopCoordinate")
    NSKeyedUnarchiver.setClass(STKStopCoordinate.self, forClassName: "STKStopCoordinate")
    NSKeyedUnarchiver.setClass(STKStopCoordinate.self, forClassName: "SGStopCoordinate")

    NSKeyedUnarchiver.setClass(SVKRegion.self, forClassName: "TripKit.SVKRegion")
    NSKeyedUnarchiver.setClass(SVKRegion.self, forClassName: "SGCoreKit.SVKRegion")
    NSKeyedUnarchiver.setClass(SVKRegion.self, forClassName: "SVKRegion")
    NSKeyedUnarchiver.setClass(SVKRegion.self, forClassName: "SGRegion")
    NSKeyedUnarchiver.setClass(SVKRegion.self, forClassName: "Region")

    NSKeyedUnarchiver.setClass(ModeInfo.self, forClassName: "TripKit.ModeInfo")
    NSKeyedUnarchiver.setClass(ModeInfo.self, forClassName: "SGCoreKit.ModeInfo")
    NSKeyedUnarchiver.setClass(ModeInfo.self, forClassName: "ModeInfo")
    
    // Give the main class a nudge to wake up
    let _ = TripKit.shared
    
    SVKServer.shared.updateRegions(forced: false)
  }
  
}
