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
  
  public static func reportPlannedTrip(_ trip: Trip, userInfo: [String: Any] = [:], includeUserID: Bool = false, completion: ((Bool) -> Void)? = nil) {
    
    guard
      let urlString = trip.plannedURLString,
      let url = URL(string: urlString) else { return }
    
    let key = "TKReporterLatestPlannedURL"
    UserDefaults.standard.set(url, forKey: key)
    
    var paras = userInfo
    paras["choiceSet"] = trip.request.choiceSet
    
    if includeUserID {
      paras["userToken"] = TKServer.userToken()
    }
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
      
      // Only report if url is still the last one planned
      guard let currentUrl = UserDefaults.standard.url(forKey: key), currentUrl == url
        else { return }
      
      UserDefaults.standard.removeObject(forKey: key)
      
      TKServer.post(url, paras: paras) { _, _, _, _, error in
        if let error = error {
          TKLog.debug("TKReporter", text: "Planned trip encountered error: \(error)")
          completion?(false)
        } else {
          TKLog.debug("TKReporter", text: "Planned trip reported successfully")
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
    
    TKServer.post(url, paras: paras) { _, _, _, _, error in
      if let error = error {
        TKLog.debug("TKReporter", text: "Progress post encountered error: \(error)")
      } else {
        TKLog.debug("TKReporter", text: "Progress posted successfully")
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
    sample["bearing"] = course >= 0 ? course : nil
    return sample
  }
  
}

extension TripRequest {
  
  
  /// Choice set information for this request
  ///
  /// What's in it:
  /// - List of maximised or minimised trips, sorted by using user's selected sort order
  /// - If trip is maximised or minimised
  /// - If trip is the selected one
  /// - Total score, total cost, total time, etc. of trip
  /// - Overview of segments
  ///   - mode
  ///   - duration
  fileprivate var choiceSet: [[String: Any]] {
    return sortedVisibleTrips().map { $0.choiceSetEntry }
  }
  
}

extension Trip {
  
  fileprivate var choiceSetEntry: [String: Any] {
    
    var entry: [String: Any] = [
      "selected": tripGroup == request.preferredGroup,
      "visibility": tripGroup.visibility.apiString,
      "score": totalScore.floatValue,
      "hassle": totalHassle.floatValue,
      "carbon": totalCarbon.floatValue,
      "calories": totalCalories.floatValue,
      "arrivalTime": arrivalTime.timeIntervalSince1970,
      "departureTime": departureTime.timeIntervalSince1970,
      "segments": (self as TKTrip).segments(with: .inDetails).compactMap { ($0 as? TKSegment)?.choiceSetEntry }
    ]

    entry["price"] = totalPrice?.floatValue
    return entry
    
  }
  
}

extension TripGroupVisibility {
  
  fileprivate var apiString: String {
    switch self {
    case .full: return "full"
    case .mini: return "minimized"
    case .hidden: return "hidden"
    }
  }
  
}

extension TKSegment {
  
  fileprivate var choiceSetEntry: [String: Any]? {
    guard order == .regular, !isContinuation else { return nil }

    let mode: String
    if isStationary {
      mode = modeInfo?.localImageName ?? "wait"
    } else if let identifier = modeInfo?.identifier ?? modeIdentifier {
      mode = identifier
    } else {
      return nil
    }
    
    return [
      "mode": mode,
      "duration": duration(true)
    ]
    
  }
  
}

