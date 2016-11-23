//
//  TKReporter.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23/11/16.
//
//

import Foundation

import CoreLocation

public class TKReporter {
  
  private init() { }
  
  public static func reportPlannedTrip(_ trip: Trip, userInfo: [String: Any], completion: ((Bool) -> Void)?) {
    
    guard
      let urlString = trip.plannedURLString,
      let url = URL(string: urlString) else { return }
    
    let key = "TKReporterLatestPlannedURL"
    UserDefaults.standard.set(url, forKey: key)
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
      
      // Only report if url is still the last one planned
      guard let currentUrl = UserDefaults.standard.url(forKey: key), currentUrl == url
        else { return }
      
      UserDefaults.standard.removeObject(forKey: key)
      
      SVKServer.post(url, paras: userInfo) { _, _, error in
        if let error = error {
          SGKLog.debug("TKReporter", text: "Planned trip encountered error: \(error)")
          completion?(false)
        } else {
          SGKLog.debug("TKReporter", text: "Planned trip reported successfully")
          completion?(true)
        }
      }
  
    }
    
  }
  
  
  public static func reportProgress(for trip: Trip, locations: [CLLocation]) {
    
    guard
      let urlString = trip.progressURLString,
      let url = URL(string: urlString) else { return }
    
    let samples = locations.map { $0.progressDict }
    let paras = [
      "samples": samples
    ]
    
    SVKServer.post(url, paras: paras) { _, _, error in
      if let error = error {
        SGKLog.debug("TKReporter", text: "Progress post encountered error: \(error)")
      } else {
        SGKLog.debug("TKReporter", text: "Progress posted successfully")
      }
    }
  }
  
}

extension CLLocation {
  
  fileprivate var progressDict: [String: Any] {
    var sample = [
      "timestamp":  timestamp.timeIntervalSince1970,
      "latitude":   coordinate.latitude,
      "longitude":  coordinate.longitude
    ]
    
    sample["speed"]   = speed  >= 0 ? speed : nil
    sample["beraing"] = course >= 0 ? course : nil
    return sample
  }
  
}

