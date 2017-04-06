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
  
  
  public static func start() {
    // Give the main class a nudge to wake up
    TKTripKit.sharedInstance()
  }
  
}
