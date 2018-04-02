//
//  TripRequest.swift
//  TripKit
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation

// MARK: Non-CoreData properties

extension TripRequest {
  
  @objc public var trips: Set<Trip> {
    guard let tripGroups = self.tripGroups else { return Set() }
    
    return tripGroups.reduce(mutating: Set()) { acc, group in
      guard let trips = group.trips as? Set<Trip> else { assertionFailure()
        return
      }
      acc.formUnion(trips)
    }
  }
  
  @objc public var type: SGTimeType {
    return SGTimeType(rawValue: self.timeType.intValue) ?? .leaveASAP
  }
  
  @objc public var time: Date? {
    switch type {
    case .none, .leaveASAP: return Date()
    case .leaveAfter: return departureTime
    case .arriveBefore: return arrivalTime
    }
  }

  /// Set the time and type for this request.
  @objc(setTime:forType:)
  public func setTime(_ time: Date?, for type: SGTimeType) {
    self.timeType = NSNumber(value: type.rawValue)
    
    switch type {
    case .leaveASAP:
      self.departureTime = Date()
      self.arrivalTime = nil
      
    case .leaveAfter:
      assert(time != nil)
      self.departureTime = time
      self.arrivalTime = nil
      
    case .arriveBefore:
      assert(time != nil)
      self.departureTime = nil
      self.arrivalTime = time
      
    case .none:
      self.departureTime = nil
      self.arrivalTime = nil
    }
  }
  
  @objc public var timeString: String {
    let timeZone = type == .arriveBefore ? arrivalTimeZone() : departureTimeZone()
    return TripRequest.timeString(for: time, timeType: type, in: timeZone)
  }
  
}

// MARK: - Inserting

extension TripRequest {
  @objc(insertEmptyIntoContext:)
  public static func insertEmpty(into context: NSManagedObjectContext) -> TripRequest {
    guard
      let request = NSEntityDescription.insertNewObject(forEntityName: "TripRequest", into: context) as? TripRequest
      else { fatalError() }
    request.timeCreated = Date()
    return request
  }
  
  @objc(insertRequestFrom:to:forTime:ofType:intoContext:)
  public static func insert(from start: MKAnnotation, to end: MKAnnotation, for time: Date?, timeType: SGTimeType, into context: NSManagedObjectContext) -> TripRequest {
    
    let request = insertEmpty(into: context)
    request.fromLocation = SGKNamedCoordinate.namedCoordinate(for: start)!
    request.toLocation = SGKNamedCoordinate.namedCoordinate(for: end)!
    
    request.setTime(time, for: timeType)
    if timeType == .leaveASAP {
      request.departureTime = nil // don't lock it in yet!
    }
    return request
  }
  
  @objc(timeStringForTime:ofType:timeZone:)
  public static func timeString(for time: Date?, timeType: SGTimeType, in timeZone: TimeZone?) -> String {
    
    switch timeType {
    case .leaveASAP:
      return NSLocalizedString("Leave now", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")

    case .none:
      return ""
    
    case .leaveAfter:
      let prefix = NSLocalizedString("Leave", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Prefix for selected 'leave after' time")
      return timeString(prefix: prefix, time: time, in: timeZone)
      
    case .arriveBefore:
      let prefix = NSLocalizedString("Arrive", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Prefix for selected 'arrive by' time")
      return timeString(prefix: prefix, time: time, in: timeZone)
      
    }
    
  }
  
  private static func timeString(prefix: String, time: Date?, in timeZone: TimeZone?) -> String {
    var string = prefix
    string.append(" ")
    
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    formatter.locale = SGStyleManager.applicationLocale()
    formatter.doesRelativeDateFormatting = true
    formatter.timeZone = timeZone
    
    if let time = time {
      var timeString = formatter.string(from: time)
      timeString = timeString.replacingOccurrences(of: " pm", with: "pm")
      timeString = timeString.replacingOccurrences(of: " am", with: "am")
      if #available(iOS 9.0, *) {
        string.append(timeString.localizedLowercase)
      } else {
        string.append(timeString.lowercased(with: SGStyleManager.applicationLocale()))
      }
    }
    
    if let offset = timeZone?.secondsFromGMT(), let short = timeZone?.abbreviation(), offset != TimeZone.current.secondsFromGMT() {
      string.append(" ")
      string.append(short)
    }
    
    return string
  }
  
  @objc public func insertCopyWithoutTrips() -> TripRequest {
    guard let context = self.managedObjectContext else {
      assertionFailure()
      return self
    }
    
    let newRequest = TripRequest.insertEmpty(into: context)
    newRequest.fromLocation = fromLocation
    newRequest.toLocation = toLocation
    newRequest.arrivalTime = arrivalTime
    newRequest.departureTime = departureTime
    newRequest.timeType = timeType
    newRequest.excludedStops = excludedStops
    return newRequest
  }
}

// MARK: - Miscellaneous

extension TripRequest {
 
  @objc
  public func _determineRegions() -> [SVKRegion] {
    let start = self.fromLocation.coordinate
    let end = self.toLocation.coordinate
    return TKRegionManager.shared.localRegions(start: start, end: end)
  }
    
  /// The primary alternatives for this request, which is constructed by
  /// taking the trip groups, sorting them by the user's selected sort
  /// orders, and then taking each group's visible trip.
  ///
  /// - SeeAlso: `sortDescriptorsAccordingToSelectedOrder`
  ///
  /// - Returns: Visible trip for each trip group sorted by user's preferences
  @objc public func sortedVisibleTrips() -> [Trip] {
    guard let set = self.tripGroups as NSSet? else { return [] }
    
    let sorters = sortDescriptorsAccordingToSelectedOrder()
    guard let sorted = set.sortedArray(using: sorters) as? [TripGroup] else {
      preconditionFailure()
    }
    
    return sorted
      .filter { $0.visibility != .hidden }
      .compactMap { $0.visibleTrip }
  }
  
  
  @objc public func sortDescriptorsAccordingToSelectedOrder() -> [NSSortDescriptor] {
    return sortDescriptors(withPrimary: TKSettings.sortOrder)
  }
  
  
  @objc public func sortDescriptors(withPrimary primary: STKTripCostType) -> [NSSortDescriptor] {
    
    let primaryTimeSorter = TripRequest.timeSorter(for: type)
    let visibilitySorter = NSSortDescriptor(key: "visibilityRaw", ascending: true)
    let scoreSorter = NSSortDescriptor(key: "visibleTrip.totalScore", ascending: true)
    
    let first: NSSortDescriptor
    var second = visibilitySorter
    var third  = primaryTimeSorter
    
    switch (primary, type) {
    case (.time, .arriveBefore):
      first  = primaryTimeSorter
      second = TripRequest.timeSorter(for: .leaveAfter)
      third  = visibilitySorter
      
    case (.time, _):
      first  = primaryTimeSorter
      second = TripRequest.timeSorter(for: .arriveBefore)
      third  = visibilitySorter
      
    case (.duration, _):
      first = NSSortDescriptor(key: "visibleTrip.minutes", ascending: true)

    case (.price, _):
      first = NSSortDescriptor(key: "visibleTrip.totalPriceUSD", ascending: true)

    case (.carbon, _):
      first = NSSortDescriptor(key: "visibleTrip.totalCarbon", ascending: true)

    case (.calories, _):
      first = NSSortDescriptor(key: "visibleTrip.totalCalories", ascending: true)
      
    case (.walking, _):
      first = NSSortDescriptor(key: "visibleTrip.totalWalking", ascending: true)

    case (.hassle, _):
      first = NSSortDescriptor(key: "visibleTrip.totalHassle", ascending: true)

    case (.count, _), (.score, _):
      first = visibilitySorter
      second = scoreSorter
      third = primaryTimeSorter
    }
    
    return [first, second, third]
  }
  
  private static func timeSorter(for type: SGTimeType, forGroups: Bool = true) -> NSSortDescriptor {
    let base = forGroups ? "visibleTrip." : ""
    if type == .arriveBefore {
      return NSSortDescriptor(key: base + "departureTime", ascending: false)
    } else {
      return NSSortDescriptor(key: base + "arrivalTime", ascending: true)
    }
  }
  
}

