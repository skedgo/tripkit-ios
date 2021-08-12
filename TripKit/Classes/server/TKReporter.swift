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
    paras["choiceSet"] = trip.request.buildChoiceSet(selected: trip)
    
    if includeUserID {
      paras["userToken"] = TKServer.userToken()
    }
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
      
      // Only report if url is still the last one planned
      guard let currentUrl = UserDefaults.standard.url(forKey: key), currentUrl == url
        else { return }
      
      UserDefaults.standard.removeObject(forKey: key)
      
      TKServer.hit(.POST, url: url, parameters: paras) { _, _, result in
        switch result {
        case .success:
          TKLog.debug("Planned trip reported successfully")
          completion?(true)
        case .failure(let error):
          TKLog.debug("Planned trip encountered error: \(error)")
          completion?(false)
        }
      }
    }
    
  }
  
  public static func reportProgress(for trip: Trip, locations: [CLLocation]) {
    guard
      let urlString = trip.progressURLString,
      let url = URL(string: urlString) else { return }
    
    let samples = locations.map(\.progressDict)
    let paras = [
      "samples": samples
    ]
    
    TKServer.hit(.POST, url: url, parameters: paras) { _, _, result in
      switch result {
      case .success:
        TKLog.debug("Progress posted successfully")
      case .failure(let error):
        TKLog.debug("Progress post encountered error: \(error)")
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
  fileprivate func buildChoiceSet(selected: Trip) -> [[String: Any]] {
    sortedVisibleTrips().map { trip in
      trip.choiceSetEntry(isSelected: trip == selected)
    }
  }
  
}

extension Trip {
  
  fileprivate func choiceSetEntry(isSelected: Bool) -> [String: Any] {
    var entry: [String: Any] = [
      "selected": isSelected,
      "visibility": tripGroup.visibility.apiString,
      "score": totalScore,
      "hassle": totalHassle,
      "carbon": totalCarbon,
      "calories": totalCalories,
      "arrivalTime": arrivalTime.timeIntervalSince1970,
      "departureTime": departureTime.timeIntervalSince1970,
      "segments": segments(with: .inDetails).compactMap(\.choiceSetEntry)
    ]

    entry["price"] = totalPrice?.floatValue
    return entry
  }
  
}

extension TKTripGroupVisibility {
  
  fileprivate var apiString: String {
    switch self {
    case .full: return "full"
    case .hidden: return "hidden"
    }
  }
  
}

extension TKSegment {
  
  fileprivate var choiceSetEntry: [String: Any]? {
    guard order == .regular, !isContinuation else { return nil }

    let mode: String
    if let identifier = modeInfo?.identifier ?? modeIdentifier {
      mode = identifier
    } else {
      return nil
    }
    
    return [
      "mode": mode,
      "duration": duration(includingContinuation: true)
    ]
  }
  
}
