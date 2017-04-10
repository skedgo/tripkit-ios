//
//  TripKit.swift
//  Pods
//
//  Created by Adrian Schoenig on 6/4/17.
//
//

import Foundation

public enum TripKit {
  
  public static var apiKey: String {
    get {
      return SVKServer.sharedInstance().apiKey
    }
    set {
      SVKServer.sharedInstance().apiKey = newValue
    }
  }
  
  
  /// Prepares TripKit to be used
  ///
  /// Should be called from the application delegate, typically from
  /// `application:didFinishLaunchingWithOptions` and
  /// `applicationWillEnterForeground`.
  public static func prepareForNewSession() {
    // Give the main class a nudge to wake up
    TKTripKit.sharedInstance()
    
    SVKServer.sharedInstance().updateRegionsForced(false)
  }
  
}
