//
//  AppDelegate.swift
//  MiniMap
//
//  Created by Adrian Schoenig on 7/7/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Cocoa

import TripKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    
    TripKit.apiKey = ProcessInfo.processInfo.environment["TRIPGO_API_KEY"] ?? "MY_API_KEY"
    TripKit.prepareForNewSession()
    
//    let start: MKAnnotation = ...
//    let end: MKAnnotation = ...
//    
//    let request = TripRequest.insert(
//      from: start, to: end,
//      for: nil, timeType: .leaveASAP,
//      into: TripKit.shared.tripKitContext
//    )
//    
//    let router = TKBuzzRouter()
//    router.modeIdentifiers = [ SVKTransportModeIdentifierRegularPublicTransport ]
//    
//    router.fetchTrips(for: request, success: { request, _ in
//      
//      let trips = request.trips()
//      // show trips
//      
//    }, failure: { error, _ in
//      // handle error
//    })
    
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
}

