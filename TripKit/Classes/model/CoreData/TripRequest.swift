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
    
    return tripGroups.reduce(into: Set()) { acc, group in
      acc.formUnion(group.trips)
    }
  }
  
  @objc public var type: TKTimeType {
    get { TKTimeType(rawValue: self.timeType.intValue) ?? .leaveASAP }
    set { timeType = NSNumber(value: newValue.rawValue) }
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
  public func setTime(_ time: Date?, for type: TKTimeType) {
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
    let request = TripRequest(context: context)
    request.timeCreated = Date()
    return request
  }
  
  @objc(insertRequestFrom:to:forTime:ofType:intoContext:)
  public static func insert(from start: MKAnnotation, to end: MKAnnotation, for time: Date?, timeType: TKTimeType, into context: NSManagedObjectContext) -> TripRequest {
    
    let request = insertEmpty(into: context)
    request.fromLocation = TKNamedCoordinate.namedCoordinate(for: start)
    request.toLocation = TKNamedCoordinate.namedCoordinate(for: end)
    
    request.setTime(time, for: timeType)
    if timeType == .leaveASAP {
      request.departureTime = nil // don't lock it in yet!
    }
    return request
  }
  
  public func emptyCopy() -> TripRequest {
    guard let context = self.managedObjectContext else { fatalError() }
    let request = Self.insertEmpty(into: context)
    request.fromLocation = fromLocation
    request.toLocation = toLocation
    request.departureTime = departureTime
    request.arrivalTime = arrivalTime
    request.timeType = timeType
    return request
  }
  
  @objc(timeStringForTime:ofType:timeZone:)
  public static func timeString(for time: Date?, timeType: TKTimeType, in timeZone: TimeZone?) -> String {
    
    switch timeType {
    case .leaveASAP:
      return NSLocalizedString("Leave now", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")

    case .none:
      return ""
    
    case .leaveAfter:
      return timeString(prefix: Loc.LeaveAt, time: time, in: timeZone)

    case .arriveBefore:
      return timeString(prefix: Loc.ArriveBy, time: time, in: timeZone)
    }
  }
  
  private static func timeString(prefix: String, time: Date?, in timeZone: TimeZone?) -> String {
    var string = prefix
    string.append(" ")
    
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .short
    formatter.locale = TKStyleManager.applicationLocale()
    formatter.doesRelativeDateFormatting = true
    formatter.timeZone = timeZone
    
    if let time = time {
      var timeString = formatter.string(from: time)
      timeString = timeString.replacingOccurrences(of: " pm", with: "pm")
      timeString = timeString.replacingOccurrences(of: " am", with: "am")
      string.append(timeString.localizedLowercase)
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
  public func _determineRegions() -> [TKRegion] {
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
  
  
  @objc public func sortDescriptors(withPrimary primary: TKTripCostType) -> [NSSortDescriptor] {
    
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
  
  public func tripTimeSortDescriptors() -> [NSSortDescriptor] {
    let primaryTimeSorter = TripRequest.timeSorter(for: type, forGroups: false)
    let visibilitySorter = NSSortDescriptor(key: "tripGroup.visibilityRaw", ascending: true)
    
    switch type {
    case .arriveBefore:
      return [
        primaryTimeSorter,
        TripRequest.timeSorter(for: .leaveAfter, forGroups: false),
        visibilitySorter
      ]
      
    default:
      return [
        primaryTimeSorter,
        TripRequest.timeSorter(for: .arriveBefore, forGroups: false),
        visibilitySorter
      ]
    }
  }
  
  private static func timeSorter(for type: TKTimeType, forGroups: Bool = true) -> NSSortDescriptor {
    let base = forGroups ? "visibleTrip." : ""
    if type == .arriveBefore {
      return NSSortDescriptor(key: base + "departureTime", ascending: false)
    } else {
      return NSSortDescriptor(key: base + "arrivalTime", ascending: true)
    }
  }
  
}

