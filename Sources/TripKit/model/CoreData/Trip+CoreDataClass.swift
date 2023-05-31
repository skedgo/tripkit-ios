//
//  Trip+CoreDataClass.swift
//  TripKit
//
//  Created by Adrian Schönig on 12/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//
//

import Foundation
import CoreData

#if os(iOS)
import UIKit
#endif

@objc(Trip)
public class Trip: NSManagedObject {
  private var _sortedSegments: [TKSegment]? = nil
  
  /// All associated segment in their correct order.
  public var segments: [TKSegment] {
    if let cached = _sortedSegments {
      return cached
    }
    let calculated = buildSortedSegments()
    _sortedSegments = calculated
    return calculated
  }
  
  /// - note: Only includes walking if it's a walking-only trip!
  public lazy var usedModeIdentifiers: Set<String> = {
    // No need to reset this as mode identifiers shouldn't change
    var walkingIdentifier: String? = nil
    let all = segments.reduce(into: Set<String>()) { acc, next in
      guard let mode = next.modeIdentifier else { return }
      if next.isWalking || next.isWheelchair {
        walkingIdentifier = mode
      } else {
        acc.insert(mode)
      }
    }
    if all.count > 0 {
      return all
    } else if let walker = walkingIdentifier {
      return [walker]
    } else {
      return []
    }
  }()
  
  /// Whether this trip has at least one reminder and the reminder icon should be displayed.
  public var hasReminder: Bool = false
  
  public override func didTurnIntoFault() {
    _sortedSegments = nil
    super.didTurnIntoFault()
  }
}

extension Trip {
  @objc
  public var request: TripRequest! { tripGroup.request }
  
  @objc
  public var shareURL: URL? {
    get { shareURLString.flatMap(URL.init) }
    set { shareURLString = newValue?.absoluteString }
  }
  
  public var saveURL: URL? { saveURLString.flatMap(URL.init) }
  
  public func setAsPreferredTrip() {
    tripGroup.visibleTrip = self
    tripGroup.request.preferredGroup = tripGroup
  }
  
  public var departureTimeZone: TimeZone {
    return request.departureTimeZone ?? .current
  }
  
  public var arrivalTimeZone: TimeZone? {
    return request.arrivalTimeZone
  }
  
  public var isArriveBefore: Bool {
    return request.type == .arriveBefore
  }

  var primaryCostType: TKTripCostType {
    if departureTimeIsFixed {
      return .time
    } else if isExpensive {
      return .price
    } else {
      return .duration
    }
  }
  
  private var isExpensive: Bool {
    let segment = mainSegment
    guard
      let identifier = segment.modeIdentifier
      else { return false }
    return TKTransportModes.modeIdentifierIsExpensive(identifier)
  }
  
  /// Offset in seconds from the specified departure/arrival time.
  /// E.g., if you asked for arrive-by, it'll use the arrival time.
  ///
  /// If the trip does not satisfy the requested time, it's negative.
  public func calculateOffset() -> TimeInterval {
    switch request.type {
    case .arriveBefore:
      return request.arrivalTime?.timeIntervalSince(arrivalTime) ?? 0
      
    case .leaveAfter:
      return departureTime.timeIntervalSince(request.departureTime ?? departureTime)
      
    case .leaveASAP, .none:
      return departureTime.timeIntervalSinceNow
    }
  }
  
  /// Trip duration, i.e., time between departure and arrival.
  @discardableResult
  func calculateDuration() -> TimeInterval {
    let minutes = arrivalTime.minutesSince(departureTime)
    
    // This can occasionally happen due to bad real-time data
    guard minutes >= Int16.min, minutes <= Int16.max else { return 0 }
    
    self.minutes = Int16(min(Double(Int16.max), Double(minutes)))
    return TimeInterval(minutes * 60)
  }
}

extension Trip {
  public static func find(tripURL: URL, in context: NSManagedObjectContext) -> Trip? {
    if tripURL.scheme == "x-coredata", let objectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: tripURL), let trip = context.object(with: objectID) as? Trip {
      return trip
    }
    
    let needle = tripURL.absoluteString
    return context.fetchUniqueObject(Trip.self, predicate: NSPredicate(format: "temporaryURLString == %@ OR shareURLString == %@", needle, needle))
  }
  
  public var tripURL: URL {
    shareURL
      ?? temporaryURLString.flatMap { URL(string: $0) }
      ?? objectID.uriRepresentation()
  }
}

// MARK: - Similar trips

extension Trip {
  static func findSimilarTrip<C>(to trip: Trip, in list: C) -> Trip? where C: Collection, C.Element == Trip {

    // this is modelled after GenericPath.java (public boolean significantlyDifferentFrom(@NotNull GenericPath other))
    let departureDifference: TimeInterval = 90
    let arrivalDifference: TimeInterval = 90
    let costDifference: Float = 0.1 // 10%

    func value(_ this: Float, isSimilarTo that: Float) -> Bool {
      let percentage: Float
      if this < 0.0001 {
        percentage = 0
      } else if that < 0.0001 {
        percentage = 1
      } else {
        percentage = 1.0 - (this / that)
      }
      return abs(percentage) < costDifference
    }

    func isSimilar(to existing: Trip, on metric: KeyPath<Trip, Float>) -> Bool {
      return value(trip[keyPath: metric], isSimilarTo: existing[keyPath: metric])
    }
    
    func isSimilar(to existing: Trip, on metric: KeyPath<Trip, NSNumber?>) -> Bool {
      if let this = trip[keyPath: metric]?.floatValue, let that = existing[keyPath: metric]?.floatValue {
        return value(this, isSimilarTo: that)
      } else {
        return true
      }
    }

    func timeIsSimilar(to existing: Trip) -> Bool {
      guard trip.departureTimeIsFixed == existing.departureTimeIsFixed else { return false }
      guard trip.departureTimeIsFixed else { return true }
      
      return abs(trip.departureTime.timeIntervalSince(existing.departureTime)) < departureDifference
          && abs(trip.arrivalTime.timeIntervalSince(existing.arrivalTime)) < arrivalDifference
    }
    
    return list.first { existing -> Bool in
      existing.usedModeIdentifiers == trip.usedModeIdentifiers
        && timeIsSimilar(to: existing)
        && isSimilar(to: existing, on: \.totalCarbon)
        && isSimilar(to: existing, on: \.totalHassle)
        && isSimilar(to: existing, on: \.totalPrice)
    }
  }
}

// MARK: - Segments

extension Trip {
  
  public var mainSegment: TKSegment {
    let hash = mainSegmentHashCode
    if hash > 0 {
      for segment in segments where segment.templateHashCode == hash {
        return segment
      }
      TKLog.warn("Warning: The main segment hash code should be the hash code of one of the segments. Hash code is: \(hash)")
    }
    
    return segments(with: .inSummary).first!
  }
  
  @objc(segmentsWithVisibility:)
  public func segments(with type: TKTripSegmentVisibility) -> [TKSegment] {
    let filtered = segments.filter { $0.hasVisibility(type) }
    return filtered.isEmpty ? segments : filtered
  }
  
  public var allPublicTransport: [TKSegment] {
    segments.filter {
      $0.isPublicTransport && !$0.isContinuation
    }
  }
  
  /// - warning: Call this before changing the segments of a trip.
  func clearSegmentCaches() {
    _sortedSegments = nil
  }
  
  private func buildSortedSegments() -> [TKSegment] {
    guard let references = segmentReferences else {
      assertionFailure()
      return []
    }
    
    let sorted = references.sorted { $0.index < $1.index }
    guard
      let start = sorted.first?.template?.start,
      let end = sorted.last?.template?.end
    else {
      assertionFailure()
      return []
    }
    
    var segments = [TKSegment(order: .start, location: start, trip: self)]
    segments.append(contentsOf: sorted.map { TKSegment(reference: $0, trip: self) })
    segments.append(TKSegment(order: .end, location: end, trip: self))
    
    for (prev, next) in zip(segments.prefix(upTo: segments.count - 1), segments.suffix(from: 1)) {
      prev.next = next
      next.previous = prev
    }
    
    return segments
  }
  
  /// Checks for intermodality. Ignores very short walks and, optionally, all walks.
  ///
  /// - Parameter ignoreWalking: If walks should be ignored completely
  /// - Returns: If trip is mixed modal (aka intermodmal)
  public func isMixedModal(ignoreWalking: Bool) -> Bool {
    var previousMode: String? = nil
    for segment in segments {
      guard !segment.isStationary, let mode = segment.modeIdentifier else {
        continue // always ignore stationary segments or modes with identifier
      }
      
      if segment.isWalking, ignoreWalking || !segment.hasVisibility(.inSummary) {
        continue // we always ignore short walks that don't make it into the summary
      }
      if let previous = previousMode, previous != mode {
        return true
      } else {
        previousMode = mode
      }
    }
    return false
  }
  
}

// MARK: - Visits

extension Trip {
  public func uses(_ visit: StopVisits) -> Bool {
    segments.contains { segment in
      segment.service == visit.service && segment.uses(visit)
    }
  }
  
  public func shouldShow(_ visit: StopVisits) -> Bool {
    segments.contains{ segment in
      segment.service == visit.service && segment.shouldShow(visit)
    }
  }
}

// MARK: - Real-time

extension Trip {
  public var isImpossible: Bool {
    segments.contains(where: \.isImpossible)
  }

  public var timesAreRealTime: Bool {
    segments.contains(where: \.timesAreRealTime)
  }
  
  public var primaryAlert: Alert? {
    segments.lazy.first { !$0.alerts.isEmpty }.flatMap { $0.alerts.first }
  }
}

// MARK: - Vehicles

extension Trip {
  
  /// If the trip uses a personal vehicle (non shared) which the user might want to assign to one of their vehicles
  public var usedPrivateVehicleType: TKVehicleType {
    for segment in segments {
      let vehicleType = segment.privateVehicleType
      if vehicleType != .unknown {
        return vehicleType
      }
    }
    return .unknown
  }
  
  /// - Parameter vehicle: The vehicle to assign this trip to. `nil` to reset to a generic vehicle.
  public func assign(_ vehicle: TKVehicular?) {
    segments.forEach { $0.assign(vehicle) }
  }
  
}

extension Trip {
  
  private func accessibilityCostValues(includeTime: Bool) -> [TKTripCostType: String] {
    var values: [TKTripCostType: String] = [
      .score: NSNumber(value: totalScore).toScoreString(),
      .calories: TKStyleManager.exerciseString(calories: Double(totalCalories)),
      .carbon: NSNumber(value: totalCarbon).toCarbonString()
    ]
    if includeTime {
      values[.duration] = arrivalTime.durationLongSince(departureTime)
    }
    if let price = totalPrice, let currency = currencyCode {
      values[.price] = price.toMoneyString(currencyCode: currency)
    }
    return values
  }

  /// Mapping of boxed `TKTripCostType` to strings of their values.
  public var costValues: [TKTripCostType : String] {
    return accessibilityCostValues(includeTime: true)
  }

  @objc
  public func constructPlainText() -> String {
    func address(for annotation: MKAnnotation) -> String? {
      return (annotation.subtitle ?? nil) ?? (annotation.title ?? nil)
    }
    
    var text = ""
    
    for segment in segments(with: .inDetails) {
      if segment.order != .start,
         !segment.isStationary,
         let start = segment.start,
         let end = segment.end,
         let name = address(for: start),
         !TKLocationHelper.coordinate(start.coordinate, isNear: end.coordinate) {
          // simple case: start is far from end: add location
          text.append(name)
          text.append(", ")
      }

      text.append(segment.singleLineInstruction ?? "")
      text.append("\n")
      
      if let notes = segment.notes, !notes.isEmpty {
        text.append("\t")
        text.append(notes)
        text.append("\n")
      }

      text.append("\n")
    }

    return text
  }

  /// Something like: `11:10-16:00; W-C-B-T-W; $3, 50m, 2kg, 5h, $total`
  public var debugString: String {
    // "11:10-16:00; W-C-B-T-W; $3, 50m, 2kg, 5h, $total
    
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    formatter.timeZone = departureTimeZone
    
    var output = ""
    output.append(formatter.string(from: departureTime))
    output.append("-")
    output.append(formatter.string(from: arrivalTime))
    output.append("; ")
    
    let letters = segments(with: .inDetails)
      .compactMap(\.modeInfo?.alt)
      .filter { !$0.isEmpty }
      .map { String($0.prefix(1)) }
    output.append(letters.joined(separator: "-"))
    output.append("; ")
    
    if let price = totalPrice, let currency = currencyCode {
      output.append(price.toMoneyString(currencyCode: currency))
      output.append(", ")
    }
    
    output.append(String(format: "%@m, %.0fCal, %.1fkg, %.0fh => %.2f", NSNumber(value: minutes), totalCalories, totalCarbon, totalHassle, totalScore))

    return output
  }

}

// MARK: - Accessibility

#if os(iOS)
extension Trip {
  public override var accessibilityLabel: String? {
    get {
      var label = ""
      
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      formatter.dateStyle = .none
      formatter.timeZone = departureTimeZone
      
      label.append(segments(with: .inDetails)
        .compactMap { segment in
          let parts = [segment.modeInfo?.alt, segment.tripSegmentModeTitle].compactMap { $0 }
          return parts.isEmpty ? nil : parts.joined(separator: " ")
        }
        .joined(separator: " - ")
      )
      
      label.append("; ")
      label.append(Loc.Trip)
      label.append("  ")
      
      if departureTimeIsFixed {
        if !hideExactTimes {
          label.append(Loc.Departs(atTime: formatter.string(from: departureTime)))
          label.append("; ")
          label.append(Loc.Arrives(atTime: formatter.string(from: arrivalTime)))
          label.append("; ")
        }
        label.append(arrivalTime.durationLongSince(departureTime))
      } else {
        label.append(arrivalTime.durationLongSince(departureTime))
        if !hideExactTimes {
          label.append("; ")
          label.append(Loc.Arrives(atTime: formatter.string(from: arrivalTime)))
        }
      }
      
      return label
    }
    set {
      // ignore
    }
  }
}
#endif

// MARK: - TKRealTimeUpdatable

/// :nodoc:
extension Trip: TKRealTimeUpdatable {
  public var wantsRealTimeUpdates: Bool {
    // We need a URL to update the trip
    guard updateURLString != nil else { return false }

    if segments.contains(where: { $0.bookingConfirmation != nil }) {
      return true // booking confirmations can update at any time
    }
    
    return wantsRealTimeUpdates(forStart: departureTime, end: arrivalTime, forPreplanning: true)
  }
}

// MARK: - UIActivityItemSource

#if os(iOS)
  
  extension Trip: UIActivityItemSource {
    
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {

      // Share the full text of the trip, if it's for a mail or we don't also
      // share the trip's URL.
      if activityType == .mail || !TKShareHelper.enableSharingOfURLs {
        return constructPlainText()
      
      } else {
        return nil
      }
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
      return request.purpose ?? Loc.Trip
    }
    
  }

#endif
