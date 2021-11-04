//
//  TKSegment+TKTripSegment.swift
//  TripKit
//
//  Created by Adrian Schönig on 23.07.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

// MARK: - TKUITripSegmentDisplayable

extension TKSegment {
  
  public var tripSegmentAccessibilityLabel: String? {
    titleWithoutTime
  }
  
  @objc
  public var tripSegmentModeTitle: String? {
    if let service = service {
      return service.number
    } else if let descriptor = modeInfo?.descriptor, !descriptor.isEmpty {
      return descriptor
    } else if !trip.isMixedModal(ignoreWalking: false), let distance = distanceInMetres {
      return MKDistanceFormatter().string(fromDistance: distance.doubleValue)
    } else {
      return nil
    }
  }

  public var tripSegmentModeSubtitle: String? {
    if timesAreRealTime {
      return isPublicTransport ? Loc.RealTime : Loc.LiveTraffic

    } else if !trip.isMixedModal(ignoreWalking: false), !isPublicTransport {
      let final = finalSegmentIncludingContinuation()
      return final.arrivalTime.durationSince(departureTime)

    } else if let friendly = distanceInMetresFriendly, let total = distanceInMetres {
      let formatter = NumberFormatter()
      formatter.numberStyle = .percent
      guard let percentage = formatter.string(from: NSNumber(value: friendly.doubleValue / total.doubleValue)) else {
        return nil
      }
      if isCycling {
        return Loc.PercentCycleFriendly(percentage)
      } else if isWheelchair {
        return Loc.PercentWheelchairFriendly(percentage)
      } else {
        return nil
      }
    
    } else {
      return nil
    }
  }

  public var tripSegmentTimeZone: TimeZone? { timeZone }
  
  public var tripSegmentModeImage: TKImage? { image() }
  
  public var tripSegmentInstruction: String {
    guard let rawString = template?.miniInstruction?.instruction else { return "" }
    let (instruction, _) = fillTemplates(input: rawString, inTitle: true, includingTime: true, includingPlatform: true)
    return instruction
  }
  
  /// A short detail expanding on `tripSegmentInstruction`.
  public var tripSegmentDetail: String? {
    guard let rawString = template?.miniInstruction?.detail else { return nil }
    let (instruction, _) = fillTemplates(input: rawString, inTitle: true, includingTime: true, includingPlatform: true)
    return instruction
  }
  
  public var tripSegmentTimesAreRealTime: Bool {
    return timesAreRealTime
  }
  
  public var tripSegmentWheelchairAccessibility: TKWheelchairAccessibility {
    return self.wheelchairAccessibility ?? .unknown
  }
  
  public var tripSegmentFixedDepartureTime: Date? {
    if isPublicTransport {
      if let frequency = frequency?.intValue, frequency > 0 {
        return nil
      } else {
        return departureTime
      }
    } else {
      return nil
    }
  }
  
  public var tripSegmentModeColor: TKColor? {
    // These are only used in segment views. We only want to
    // colour public transport there.
    guard isPublicTransport else { return nil }
    
    // Prefer service colour over that of the mode itself.
    return service?.color ?? modeInfo?.color
  }
  
  public var tripSegmentModeImageURL: URL? {
    return imageURL(for: .listMainMode)
  }
  
  public var tripSegmentModeImageIsTemplate: Bool {
    guard let modeInfo = modeInfo else { return false }
    return modeInfo.remoteImageIsTemplate || modeInfo.identifier.map(TKRegionManager.shared.remoteImageIsTemplate) ?? false
  }
  
  public var tripSegmentModeImageIsBranding: Bool {
    return modeInfo?.remoteImageIsBranding ?? false
  }
  
  public var tripSegmentModeInfoIconType: TKInfoIconType {
    let modeAlerts = alerts
      .filter { $0.isForMode }
      .sorted { $0.alertSeverity.rawValue > $1.alertSeverity.rawValue }

    return modeAlerts.first?.infoIconType ?? .none
  }

  public var tripSegmentSubtitleIconType: TKInfoIconType {
    let nonModeAlerts = alerts
      .filter { !$0.isForMode }
      .sorted { $0.alertSeverity.rawValue > $1.alertSeverity.rawValue }

    return nonModeAlerts.first?.infoIconType ?? .none
  }

}

// MARK: - Visits

extension TKSegment {
  
  func buildSegmentVisits() -> [String: Bool]? {
    guard let service = service else { return [:] }   // Don't ask again
    guard service.hasServiceData else { return nil } // Ask again later
    
    let untravelledEachSide = 5
    var output: [String: Bool] = [:]
    var unvisited: [String] = []
    var isTravelled = false
    var isEnd = false
    var target = scheduledStartStopCode
    
    for visit in service.sortedVisits {
      let current = visit.stop.stopCode
      if target == current {
        if !isTravelled {
          // found start
          target = scheduledEndStopCode ?? ""
        } else {
          isEnd = true
          target = nil
        }
        isTravelled.toggle()
        output[current] = true
      } else {
        // on the way
        output[current] = isTravelled
        if !isTravelled {
          unvisited.append(current)
          if isEnd, unvisited.count >= untravelledEachSide {
            break // added enough
          }
        }
      }
      
      // remove unvisited from the start if we have to
      if isTravelled, !unvisited.isEmpty {
        if unvisited.count > untravelledEachSide {
          let toRemove = unvisited.reversed().suffix(from: untravelledEachSide)
          toRemove.forEach { output.removeValue(forKey: $0) }
        }
        unvisited.removeAll()
      }
    }
    return output
  }
  
}

// MARK: - Content builder

extension TKSegment {
  func buildPrimaryLocationString() -> String? {
    guard order == .regular else { return nil }
    
    if isStationary || isContinuation {
      let departure = (start?.title ?? nil) ?? ""
      return departure.isEmpty ? nil : departure
    
    } else if isPublicTransport {
      let departure = (start?.title ?? nil) ?? ""
      return departure.isEmpty ? nil : Loc.From(location: departure)

    } else {
      let destination = (finalSegmentIncludingContinuation().end?.title ?? nil) ?? ""
      return destination.isEmpty ? nil : Loc.To(location: destination)
    }
  }
  
  func buildSingleLineInstruction(includingTime: Bool, includingPlatform: Bool) -> (String, Bool) {
    switch order {
    case .start:
      let isTimeDependent = includingTime && trip.departureTimeIsFixed
      let name: String?
      if let named = trip.request.fromLocation.name {
        name = named
      } else if isPublicTransport, let next = (next?.start?.title ?? nil) {
        name = next
      } else {
        name = trip.request.fromLocation.address ?? (next?.start?.title ?? nil)
      }
      if matchesQuery() {
        let time = isTimeDependent ? TKStyleManager.timeString(departureTime, for: timeZone) : nil
        return (Loc.LeaveFromLocation(name, at: time), isTimeDependent)
      } else {
        return (Loc.LeaveNearLocation(name), isTimeDependent)
      }
      
    case .regular:
      guard let raw = _rawAction else { return ("", false) }
      return fillTemplates(input: raw, inTitle: true, includingTime: includingTime, includingPlatform: includingPlatform)
      
    case .end:
      let isTimeDependent = includingTime && trip.departureTimeIsFixed
      let name: String?
      if let named = trip.request.toLocation.name {
        name = named
      } else if isPublicTransport, let next = (previous?.end?.title ?? nil) {
        name = next
      } else {
        name = trip.request.toLocation.address ?? (previous?.end?.title ?? nil)
      }
      if matchesQuery() {
        let time = isTimeDependent ? TKStyleManager.timeString(arrivalTime, for: timeZone) : nil
        return (Loc.ArriveAtLocation(name, at: time), isTimeDependent)
      } else {
        return (Loc.ArriveNearLocation(name), isTimeDependent)
      }
    }
  }
  
  func fillTemplates(input: String, inTitle: Bool, includingTime: Bool, includingPlatform: Bool) -> (String, Bool) {
    var isDynamic = false
    var output = input
    
    output["<NUMBER>"]    = scheduledServiceNumber.nonEmpty ?? tripSegmentModeTitle
    output["<LINE_NAME>"] = service?.lineName
    output["<DIRECTION>"] = service?.direction.map { Loc.Direction + ": " + $0 }
    output["<LOCATIONS>"] = nil // we show these as stationary segments
    output["<PLATFORM>"]  = includingPlatform ? scheduledStartPlatform : nil
    output["<STOPS>"]     = Loc.Stops(numberOfStopsIncludingContinuation())
    
    if includingTime, let range = output.range(of: "<TIME>") {
      let timeString = TKStyleManager.timeString(departureTime, for: timeZone)
      let prepend = range.lowerBound != output.startIndex && output[output.index(range.lowerBound, offsetBy: -1)] != "\n"
      output["<TIME>"] = prepend ? Loc.SomethingAt(time: timeString) : timeString
      isDynamic = true
    } else {
      output["<TIME>"] = nil
    }
    
    if let range = output.range(of: "<DURATION>") {
      let durationString = finalSegmentIncludingContinuation().arrivalTime.durationSince(departureTime)
      let prepend = inTitle && range.lowerBound != output.startIndex
      output["<DURATION>"] = prepend ? " " + Loc.SomethingFor(duration: durationString) : durationString
      isDynamic = true
    } else {
      output["<DURATION>"] = nil
    }
    
    if output.contains("<TRAFFIC>") {
      output["<TRAFFIC>"] = durationStringWithoutTraffic()
      isDynamic = true // even though the "duration without traffic" itself isn't time dependent, whether it is visible or not IS time dependent
    } else {
      output["<TRAFFIC>"] = nil
    }
    
    // replace empty lead-in
    output.replace("^: ", with: "", regex: true)
    output.replace("([\\n^])[ ]*⋅[ ]*", with: "$1", regex: true)

    // replace empty lead-out
    output.replace("[ ]*⋅[ ]*$", with: "", regex: true)
    
    // replace empty stuff between dots
    output.replace("⋅[ ]*⋅", with: "⋅", regex: true)
    
    // replace empty lines
    output.replace("^\\n*", with: "", regex: true)
    
    output.replace("  ", with: " ")
    
    while let range = output.range(of: "\n\n") {
      output.replaceSubrange(range, with: "\n")
    }
    output.replace("\\n*$", with: "")
    
    return (output, isDynamic)
  }
  
  private func numberOfStopsIncludingContinuation() -> Int {
    var stops = 0
    var candidate: TKSegment? = self
    while let segment = candidate {
      stops += segment.scheduledServiceStops
      candidate = (segment.next?.isContinuation == true) ? segment.next : nil
    }
    return stops
  }
  
  private func durationStringWithoutTraffic() -> String? {
    guard durationWithoutTraffic > 0 else { return nil }
    
    let withTraffic = arrivalTime.timeIntervalSince(departureTime)
    if withTraffic > durationWithoutTraffic + 60 {
      let durationString = Date.durationString(forMinutes: Int(durationWithoutTraffic) / 60)
      return Loc.DurationWithoutTraffic(durationString)
    } else {
      return nil
    }
  }
}

extension String {
  subscript(template: String) -> String? {
    get { assertionFailure(); return nil }
    set {
      if let range = range(of: template) {
        replaceSubrange(range, with: newValue ?? "")
      }
    }
  }
  
  mutating func replace(_ this: String, with that: String, regex: Bool = false) {
    let mutable = NSMutableString(string: self)
    mutable.replaceOccurrences(of: this, with: that, options: regex ? .regularExpression : .literal, range: NSRange(location: 0, length: mutable.length))
    self = mutable as String
  }
}

extension Alert {
  fileprivate var isForMode: Bool {
    if idService != nil {
      return true
    } else if location != nil {
      return false
    } else {
      return idStopCode != nil
    }
  }
}

extension Optional where Wrapped == String {
  fileprivate var isEmpty: Bool {
    switch self {
    case .none: return true
    case .some(let string): return string.isEmpty
    }
  }
  
  fileprivate var nonEmpty: String? {
    return isEmpty ? self : nil
  }
}
