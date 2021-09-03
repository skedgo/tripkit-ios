//
//  TripRequest+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData

@objc(TripRequest)
public class TripRequest: NSManagedObject {

  private var requestedModes: Set<String>? = nil
  private var localRegions: [TKRegion]? = nil
  
  public override func didTurnIntoFault() {
    super.didTurnIntoFault()
    requestedModes = nil
    localRegions = nil
  }
  
}

// MARK: Non-CoreData properties

extension TripRequest {

  var preferredTrip: Trip? {
    get {
      preferredGroup?.visibleTrip
    }
    set {
      newValue?.setAsPreferredTrip() // sets preferred group, too
    }
  }
  
  public var hasTrips: Bool {
    !tripGroups.isEmpty
  }
  
  @objc public var trips: Set<Trip> {
    return tripGroups.reduce(into: Set()) { acc, group in
      acc.formUnion(group.trips)
    }
  }
  
  @objc public var type: TKTimeType {
    get { TKTimeType(rawValue: Int(self.timeType)) ?? .leaveASAP }
    set { timeType = Int16(newValue.rawValue) }
  }
  
  @objc public var time: Date? {
    switch type {
    case .none, .leaveASAP: return Date()
    case .leaveAfter: return departureTime
    case .arriveBefore: return arrivalTime
    }
  }

  /// Set the time and type for this request.
  public func setTime(_ time: Date?, for type: TKTimeType) {
    self.timeType = Int16(type.rawValue)
    
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
    let timeZone = type == .arriveBefore ? arrivalTimeZone : departureTimeZone
    return TripRequest.timeString(for: time, timeType: type, in: timeZone)
  }
  
}

// MARK: - Inserting

extension TripRequest {
  public static func insert(from start: MKAnnotation, to end: MKAnnotation, for time: Date?, timeType: TKTimeType, into context: NSManagedObjectContext) -> TripRequest {
    
    let request = TripRequest(context: context)
    request.timeCreated = Date()
    request.fromLocation = TKNamedCoordinate.namedCoordinate(for: start)
    request.toLocation = TKNamedCoordinate.namedCoordinate(for: end)
    
    request.setTime(time, for: timeType)
    if timeType == .leaveASAP {
      request.departureTime = nil // don't lock it in yet!
    }
    return request
  }
  
  static func timeString(for time: Date?, timeType: TKTimeType, in timeZone: TimeZone?) -> String {
    
    switch timeType {
    case .leaveASAP:
      return NSLocalizedString("Leave now", tableName: "TripKit", bundle: .tripKit, comment: "")

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
    formatter.locale = .current
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
}

// MARK: - Regions

extension TripRequest {
  
  
  /// The region the complete trip takes place in. Can be international if it spanning more than one region.
  public var spanningRegion: TKRegion {
    TKRegionManager.shared.region(containing: fromLocation.coordinate, toLocation.coordinate)
  }
  
  /// The local region this trip starts in. Cannot be international and thus might be nil.
  public var startRegion: TKRegion? {
    if localRegions == nil {
      localRegions = determineRegions()
    }
    return localRegions?.first
  }
  
  /// The local region this trip ends in. Cannot be international and thus might be nil.
  public var endRegion: TKRegion? {
    if localRegions == nil {
      localRegions = determineRegions()
    }
    return localRegions?.last
  }
  
  public var departureTimeZone: TimeZone? {
    TKRegionManager.shared.timeZone(for: fromLocation.coordinate)
  }
  
  public var arrivalTimeZone: TimeZone? {
    TKRegionManager.shared.timeZone(for: toLocation.coordinate)
  }
  
  private func determineRegions() -> [TKRegion] {
    let start = fromLocation.coordinate
    let end = toLocation.coordinate
    return TKRegionManager.shared.localRegions(start: start, end: end)
  }
  
  
  public var applicableModeIdentifiers: [String] {
    let touched: Set<TKRegion> = {
      var regions = Set(TKRegionManager.shared.localRegions(start: fromLocation.coordinate, end: toLocation.coordinate))
      if regions.count > 1 {
        regions.insert(.international)
      }
      return regions
    }()
    
    if touched.count == 1, let first = touched.first {
      return first.modeIdentifiers
    }
    
    return touched.reduce(into: Set<String>()) { acc, next in
      acc.formUnion(Set(next.modeIdentifiers))
    }
    .sorted()
  }
  
}

// MARK: - Sorting

extension TripRequest {
    
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
      .compactMap { $0.visibleTrip }
  }
  
  private func sortDescriptorsAccordingToSelectedOrder() -> [NSSortDescriptor] {
    return sortDescriptors(withPrimary: TKSettings.sortOrder)
  }
  
  public func sortDescriptors(withPrimary primary: TKTripCostType) -> [NSSortDescriptor] {
    
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

// MARK: - Debugging

extension TripRequest {
  public var debugString: String {
    var output = "\(tripGroups.count) groups:\n"
    output.append(sortedVisibleTrips().map { "\t- \($0.debugString)" }.joined(separator: "\n"))
    return output
  }
}
