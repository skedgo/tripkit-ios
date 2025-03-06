//
//  StopVisits+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

#if canImport(CoreData)

import Foundation
import CoreData
import CoreLocation
import MapKit

#if canImport(UIKit)
import UIKit
#endif

@objc(StopVisits)
public class StopVisits: NSManagedObject {
}

extension StopVisits: Comparable {
  public static func < (lhs: StopVisits, rhs: StopVisits) -> Bool {
    if lhs.index >= 0, lhs.service == rhs.service {
      return lhs.index < rhs.index
    } else if let leftTime = lhs.departure ?? lhs.arrival, let rightTime = rhs.departure ?? rhs.arrival {
      return leftTime < rightTime
    } else {
      assertionFailure()
      return false
    }
  }
}

extension StopVisits {
  
  public static var defaultSortDescriptors: [NSSortDescriptor] {
    [NSSortDescriptor(key: "departure", ascending: true)]
  }
  
  public static func departuresPredicate(stops: [StopLocation], from date: Date, filter: String = "") -> NSPredicate {
    if filter.isEmpty {
      return NSPredicate(format: "stop IN %@ AND ((departure != nil AND departure > %@) OR (arrival != nil AND arrival > %@))", stops, date as CVarArg, date as CVarArg)
    } else {
      return NSPredicate(format: "stop IN %@ AND ((departure != nil AND departure > %@) OR (arrival != nil AND arrival > %@)) AND (service.number CONTAINS[c] %@ OR service.name CONTAINS[c] %@ OR stop.shortName CONTAINS[c] %@ OR searchString CONTAINS[c] %@)", stops, date as CVarArg, date as CVarArg, filter, filter, filter, filter)
    }
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
  
  public var departurePlatform: String? {
    startPlatform?.trimmedNonEmpty ?? stop.shortName?.trimmedNonEmpty
  }

  /// :nodoc:
  public var smsString: String? {
    guard let serviceId = service.shortIdentifier else {
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
  public var timeForServerRequests: Date {
    return departure ?? arrival ?? Date()
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
      label.append(realTimeInformation(withOriginalTime: false))
    }
    
    return label
  }
  
}

extension StopVisits {
  
  func adjustRegionDay() {
    if let departure = departure {
      regionDay = departure.midnight(in: stop?.region?.timeZone ?? .current)
    } else if let arrival = arrival {
      regionDay = arrival.midnight(in: stop?.region?.timeZone ?? .current)
    } else {
      assertionFailure("We neither have an arrival nor a departure!")
    }
  }
  
}

// MARK: - Real-time information

extension StopVisits {
  
  public func triggerRealTimeKVO() {
    let timing = self.timing
    self.timing = timing
  }
  
  public enum RealTime: Hashable {
    /// We don't have real-time for this kind of service
    case notApplicable
    
    /// Services like this can have real-time, but this doesn't
    case notAvailable
    case onTime
    case early(minutes: Int, before: Date)
    case late(minutes: Int, after: Date)
    case canceled
  }
  
  public var realTimeStatus: RealTime {
    if service.isCanceled {
      return .canceled
    } else if !service.isRealTimeCapable {
      return .notApplicable
    } else if !service.isRealTime {
      return .notAvailable
    }
    
    guard let time = departure ?? arrival else {
      return .notApplicable
    }
    guard let original = originalTime else {
      return .onTime
    }
    
    if time == original {
      return .onTime
    } else {
      // do they display differently
      let realTime = Int(time.timeIntervalSince1970) - (Int(time.timeIntervalSince1970) % 60)
      let timeTable = Int(original.timeIntervalSince1970) - (Int(original.timeIntervalSince1970) % 60)
      let minutes = (realTime - timeTable) / 60
      if minutes > 1 {
        return .late(minutes: minutes, after: original)
      } else if minutes < -1 {
        return .early(minutes: abs(minutes), before: original)
      } else {
        return .onTime
      }
    }
  }
  
  public func realTimeInformation(withOriginalTime: Bool) -> String {
    switch realTimeStatus {
    case .notApplicable: return Loc.Scheduled
    case .notAvailable: return Loc.NoRealTimeAvailable
    case .canceled: return Loc.Cancelled
    case .onTime: return Loc.OnTime
    
    case .late(let minutes, let original):
      return Loc.LateService(minutes: minutes, service: withOriginalTime ? TKStyleManager.timeString(original, for: timeZone) : nil)
    case .early(let minutes, let original):
      return Loc.EarlyService(minutes: minutes, service: withOriginalTime ? TKStyleManager.timeString(original, for: timeZone) : nil)
    }
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
  @objc public var wantsRealTimeUpdates: Bool {
    return service.wantsRealTimeUpdates
  }
}


// MARK: - UIActivityItemSource

#if canImport(UIKit)
  
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
        let format = NSLocalizedString("I'll take a %@ at %@ from %@.", tableName: "TripKit", bundle: .tripKit, comment: "Indication of an activity. (old key: ActivityIndication)")
        return String(format: format,
                      service.shortIdentifier ?? "",
                      departureTime,
                      stop.name ?? stop.stopCode
        )
        
      } else {
        let format = NSLocalizedString("I'll take a %@ from %@.", tableName: "TripKit", bundle: .tripKit, comment: "Indication of an activity.")
        return String(format: format,
                      service.shortIdentifier ?? "",
                      stop.name ?? stop.stopCode
        )
      }
      
    }
    
  }
  
#endif

#endif
