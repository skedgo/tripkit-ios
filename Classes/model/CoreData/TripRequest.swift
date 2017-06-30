//
//  TripRequest.swift
//  Pods
//
//  Created by Adrian Schoenig on 18/11/16.
//
//

import Foundation

// MARK: Non-CoreData properties

extension TripRequest {
  
  public var trips: Set<Trip> {
    guard let tripGroups = self.tripGroups else { return Set() }
    
    return tripGroups.reduce(mutating: Set()) { acc, group in
      guard let trips = group.trips as? Set<Trip> else { assertionFailure()
        return
      }
      acc.formUnion(trips)
    }
  }
  
  public var type: SGTimeType {
    return SGTimeType(rawValue: self.timeType.intValue) ?? .leaveASAP
  }
  
  public var time: Date? {
    switch type {
    case .none, .leaveASAP: return Date()
    case .leaveAfter: return departureTime
    case .arriveBefore: return arrivalTime
    }
  }

  /// Set the time and type for this request.
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
  
  public var timeString: String {
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
      string.append(timeString.localizedLowercase)
    }
    
    if let offset = timeZone?.secondsFromGMT(), let short = timeZone?.abbreviation(), offset != TimeZone.current.secondsFromGMT() {
      string.append(" ")
      string.append(short)
    }
    
    return string
  }
  
  public func insertCopyWithoutTrips() -> TripRequest {
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
    return newRequest
  }
}

// MARK: - Miscellaneous

extension TripRequest {
 
  public func determineRegions() -> [SVKRegion] {
    let start = self.fromLocation.coordinate
    let end = self.toLocation.coordinate
    return SVKRegionManager.sharedInstance().localRegions(start: start, end: end)
  }
  
  /// The primary alternatives for this request, which is constructed by
  /// taking the trip groups, sorting them by the user's selected sort
  /// orders, and then taking each group's visible trip.
  ///
  /// - SeeAlso: `sortDescriptorsAccordingToSelectedOrder`
  ///
  /// - Returns: Visible trip for each trip group sorted by user's preferences
  public func sortedVisibleTrips() -> [Trip] {
    guard let set = self.tripGroups as NSSet? else { return [] }
    
    let sorters = sortDescriptorsAccordingToSelectedOrder()
    guard let sorted = set.sortedArray(using: sorters) as? [TripGroup] else {
      preconditionFailure()
    }
    
    return sorted
      .filter { $0.visibility != .hidden }
      .flatMap { $0.visibleTrip }
  }
  
  
  public func sortDescriptors(withPrimary primary: STKTripCostType) -> [NSSortDescriptor] {
    
    // TODO: Convert
    
    return []
    
  }
  
}

