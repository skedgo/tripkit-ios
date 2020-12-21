//
//  StopVisits.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

extension StopVisits {
  
  @objc
  public func triggerRealTimeKVO() {
    let timing = self.timing
    self.timing = timing
  }
  
  @objc
  public var timeZone: TimeZone { stop.timeZone ?? .current }
  
  @objc
  public var frequency: NSNumber? { service.frequency }
  
  public var timing: TKServiceTiming {
    get {
      if let minutes = service.frequency?.intValue {
        return .frequencyBased(frequency: TimeInterval(minutes * 60), start: departure, end: arrival, totalTravelTime: nil)
        
      } else {
        return .timetabled(arrival: arrival, departure: departure)
      }
    }
    set {
      // KVO
    }
  }
  
  /// :nodoc:
  public var smsString: String? {
    guard let serviceId = service.shortIdentifier() else {
      return nil
    }
    
    var output = serviceId
    
    switch timing {
    case .timetabled(let arrival, let departure):
      if let departure = departure {
        output += " " + Loc.Departs(atTime: TKStyleManager.timeString(departure, for: timeZone))
      } else if let arrival = arrival {
        output += " " + Loc.Arrives(atTime: TKStyleManager.timeString(arrival, for: timeZone))
      }
      
    case .frequencyBased(let frequency, let start, let end, _):
      let freqString = Date.durationString(forMinutes: Int(frequency/60))
      
      if let start = start, let end = end {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        output += " \(formatter.string(from: start, to: end))" + " " + Loc.Every(repetition: freqString)
      } else if let start = start {
        output += " " + Loc.From(date: TKStyleManager.timeString(start, for: timeZone)) + " " + Loc.Every(repetition: freqString)
      } else if let end = end {
        output += " " + Loc.To(date: TKStyleManager.timeString(end, for: timeZone)) + " " + Loc.Every(repetition: freqString)
      }
    }
    
    if service.isRealTime {
      output.append("*")
    }
    
    return output
  }
  
  /// :nodoc:
  @objc
  public var timeForServerRequests: Date {
    return departure ?? arrival ?? Date()
  }

  /// Legacy-code for TripGo. Should not be used anymore.
  /// :nodoc:
  @objc public func grouping(previous: StopVisits?, next: StopVisits?) -> TKGrouping {
    let sameAsBefore = previous?.searchString == searchString
    let sameAsAfter = next?.searchString == searchString
    
    switch (sameAsBefore, sameAsAfter) {
    case (true, true): return .middle
    case (true, _):    return .end
    case (_, true):    return .start
    default:           return .individual
    }
  }
  
  @objc
  public func accessibilityDescription(includeRealTime: Bool) -> String {
    var label = ""

    if let number = service.number, !number.isEmpty {
      label.append(number)
    }
    if let direction = service.direction {
      label.append(";")
      label.append(direction)
    }
    
    if self is DLSEntry {
      if let departure = departure {
        label.append(";")
        label.append(Loc.Departs(atTime: TKStyleManager.timeString(departure, for: timeZone)))
      }
      if let arrival = arrival {
        label.append(";")
        label.append(Loc.Arrives(atTime: TKStyleManager.timeString(arrival, for: timeZone)))
      }
    } else if let time = departure ?? arrival {
      label.append(";")
      label.append(Loc.At(time: TKStyleManager.timeString(time, for: timeZone)))
    }
    
    if includeRealTime {
      label.append(";")
      label.append(realTimeInformation(false))
    }
    
    return label
  }
  
}

// MARK: - MKAnnotation

extension StopVisits: MKAnnotation {
  
  public var title: String? {
    switch timing {
    case .timetabled(let arrival, let departure):
      if let departure = departure {
        return TKStyleManager.timeString(departure, for: timeZone)
      } else if let arrival = arrival {
        return TKStyleManager.timeString(arrival, for: timeZone)
      } else {
        return stop.title
      }
    case .frequencyBased:
      return stop.title
    }
  }
  
  public var subtitle: String? {
    switch timing {
    case .timetabled(let arrival, let departure):
      if departure != nil || arrival != nil {
        return stop.title
      } else {
        return nil
      }
    case .frequencyBased:
      return nil
    }
  }
  
  public var coordinate: CLLocationCoordinate2D {
    return stop.coordinate
  }
  
}



// MARK: - TKRealTimeUpdatable

/// :nodoc:
extension StopVisits: TKRealTimeUpdatable {
  public var wantsRealTimeUpdates: Bool {
    return service.wantsRealTimeUpdates
  }
  
  public var objectForRealTimeUpdates: Any {
    return self
  }
  
  public var regionForRealTimeUpdates: TKRegion {
    return stop.region ?? .international
  }
}


// MARK: - UIActivityItemSource

#if os(iOS)
  
  extension StopVisits: UIActivityItemSource {
    
    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
      return service.modeTitle ?? ""
    }
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
      
      if case .timetabled(_, let maybeDeparture) = timing, let departure = maybeDeparture {
        let departureTime = TKStyleManager.timeString(departure, for: timeZone)
        let format = NSLocalizedString("I'll take a %@ at %@ from %@.", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Indication of an activity. (old key: ActivityIndication)")
        return String(format: format,
                      service.shortIdentifier() ?? "",
                      departureTime,
                      stop.name ?? stop.stopCode
        )
        
      } else {
        let format = NSLocalizedString("I'll take a %@ from %@.", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Indication of an activity.")
        return String(format: format,
                      service.shortIdentifier() ?? "",
                      stop.name ?? stop.stopCode
        )
      }
      
    }
    
  }
  
#endif
