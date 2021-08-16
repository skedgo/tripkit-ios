//
//  TripGroup+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TripGroup)
public class TripGroup: NSManagedObject {

  private var indexToPairIdentifiers: [Int: Set<String>] = [:]
  
}

extension TripGroup {
  
  public enum Visibility: Int16 {
    case full   = 0
    case hidden = 2
  }
  
  public var visibility: Visibility {
    get {
      Visibility(rawValue: visibilityRaw) ?? .full
    }
    set {
      visibilityRaw = newValue.rawValue
    }
  }

  public var sources: [TKAPI.DataAttribution] {
    get {
      guard let sourcesRaw = sourcesRaw else { return [] }
      
      return sourcesRaw.compactMap { rawSource -> TKAPI.DataAttribution? in
        let decoder = JSONDecoder()
        return try? decoder.decode(TKAPI.DataAttribution.self, withJSONObject: rawSource)
      }
    }
    set {
      do {
        let encoded = try JSONEncoder().encodeJSONObject(newValue)
        self.sourcesRaw = (encoded as? [NSCoding & NSObjectProtocol]) ?? []
      } catch {
        TKLog.warn("Error saving sources: \(error)")
      }
    }
  }
  
  func adjustVisibleTrip() {
    /// Use the trip with the lowest score, that's not impossible
    self.visibleTrip = trips.min()
  }
  
  var usedModeIdentifiers: Set<String> {
    visibleTrip?.usedModeIdentifiers ?? []
  }
  
}

extension Trip: Comparable {
  public static func < (lhs: Trip, rhs: Trip) -> Bool {
    if lhs.isCanceled || lhs.isImpossible {
      return false
    } else if rhs.isCanceled || rhs.isImpossible {
      return true
    } else {
      return lhs.totalScore < rhs.totalScore
    }
  }
}

// MARK: - DLS caches

extension TripGroup {
  
  func cache(pairIdentifiers: Set<String>, for segment: TKSegment) {
    guard let index = segment.trip.allPublicTransport.firstIndex(of: segment) else {
      return assertionFailure()
    }
    indexToPairIdentifiers[index] = pairIdentifiers
  }
  
  func cachedPairIdentifier(for segment: TKSegment) -> Set<String>? {
    guard let index = segment.trip.allPublicTransport.firstIndex(of: segment) else {
      assertionFailure()
      return nil
    }
    return indexToPairIdentifiers[index]
  }
  
}

// MARK: - Accessibility

#if os(iOS)
extension TripGroup {
  public override var accessibilityLabel: String? {
    get {
      guard let trip = visibleTrip else { return nil }
      var label = trip.accessibilityLabel ?? ""
      label.append(" - ")
      label.append(trip.costValues.values.joined(separator: "; "))
      return label
    }
    set {
      // Ignore
    }
  }
}
#endif

// MARK: - Debugging

extension TripGroup {
  
  public var debugString: String {
    var output = "\(trips.count) trips with freq. \(frequency ?? -1):\n"
    output.append(trips.map { trip -> String in
      "\t- " + (trip == visibleTrip ? "★ " : "") + trip.debugString
    }.joined(separator: "\n"))
    return output
  }
  
}
