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
  
  
  /// Whether a per-installation identifier should be passed
  /// along with server calls to track usage from an installation
  /// across sessions.
  ///
  /// Default is to allow tracking.
  public static var allowTracking: Bool {
    get {
      if let raw = UserDefaults.standard.object(forKey: SVKDefaultsKeyProfileTrackUsage) as? NSNumber {
        return raw.boolValue
      } else {
        return true
      }
    }
    set {
      UserDefaults.standard.set(newValue, forKey: SVKDefaultsKeyProfileTrackUsage)
    }
  }
  
  
  /// Prepares TripKit to be used
  ///
  /// Should be called from the application delegate, typically from
  /// `application:didFinishLaunchingWithOptions` and
  /// `applicationWillEnterForeground`.
  public static func prepareForNewSession() {
    // Give the main class a nudge to wake up
    let _ = TripKit.shared
    
    SVKServer.shared.updateRegions(forced: false)
  }
  
}
