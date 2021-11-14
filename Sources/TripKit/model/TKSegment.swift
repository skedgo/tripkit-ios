//
//  TKSegment.swift
//  TripKit
//
//  Created by Adrian Schoenig on 31/10/16.
//
//

import Foundation
import MapKit

@objc
public enum TKSegmentOrdering: Int {
  case start   = 1
  case regular = 2
  case end     = 4
}

@objc
public enum TKSegmentType: Int {
  case unknown   = 0
  case stationary
  case scheduled
  case unscheduled
}

public class TKSegment: NSObject {
  @objc public let order: TKSegmentOrdering
  @objc public let start: MKAnnotation?
  @objc public let end: MKAnnotation?
  
  @objc public weak var previous: TKSegment?
  @objc public weak var next: TKSegment?
  
  @objc public private(set) var trip: Trip! // practically nonnull, but can be nulled due to weak reference
  let reference: SegmentReference?
  var template: SegmentTemplate? { reference?.template }
  
  private lazy var primaryLocationString: String? = buildPrimaryLocationString()
  
  // MARK: - Initialisation
  
  @objc(initAsTerminal:atLocation:forTrip:)
  public init(order: TKSegmentOrdering, location: MKAnnotation, trip: Trip) {
    assert(order != .regular, "Terminal can't be of regular order")
    
    self.order = order
    self.trip = trip
    self.start = location
    self.end = location
    self.reference = nil
    
    super.init()
  }

  init(reference: SegmentReference, trip: Trip) {
    self.order = .regular
    self.trip = trip
    self.reference = reference
    
    let template = reference.template
    assert(template != nil, "Template missing for \(reference)")
    assert(template?.start != nil, "Template is missing start: \(String(describing: template))")
    assert(template?.end != nil, "Template is missing end: \(String(describing: template))")
    self.start = template?.start
    self.end = template?.end
    
    super.init()
  }
  
  
  // MARK: - Inferred properties: Main
  
  @objc public internal(set) var departureTime: Date {
    get {
      // A segment might lose its trip, if the trip since got updated with
      // real-time information and the segments got rebuild
      guard trip != nil else { return Date() }

      switch order {
      case .start:    return trip.departureTime
      case .regular:  return reference?.startTime ?? Date()
      case .end:      return trip.arrivalTime
      }
    }
    set {
      switch order {
      case .start:    trip.departureTime    = newValue
      case .regular:  reference?.startTime  = newValue
      case .end:      trip.arrivalTime      = newValue
      }
    }
  }

  @objc public internal(set) var arrivalTime: Date {
    get {
      // A segment might lose its trip, if the trip since got updated with
      // real-time information and the segments got rebuild
      guard trip != nil else { return Date() }

      switch order {
      case .start:    return trip.departureTime
      case .regular:  return reference?.endTime ?? Date()
      case .end:      return trip.arrivalTime
      }
    }
    set {
      switch order {
      case .start:    trip.departureTime    = newValue
      case .regular:  reference?.endTime    = newValue
      case .end:      trip.arrivalTime      = newValue
      }
    }
  }
  
  lazy var localRegions: [TKRegion] = {
    guard let start = self.start?.coordinate, let end = self.end?.coordinate else { return [] }
    return TKRegionManager.shared.localRegions(start: start, end: end)
  }()
  
  /// The local region this segment starts in. Cannot be international and thus might be nil.
  public var startRegion: TKRegion? { localRegions.first }

  /// The local region this segment starts in. Cannot be international and thus might be nil.
  public var endRegion: TKRegion? { localRegions.last }

  /// the transport mode identifier that this segment is using (if any). Can return `nil` for stationary segments such as "leave your house" or "wait between two buses" or "park your car"
  @objc public lazy var modeIdentifier: String? = template?.modeIdentifier
  
  @objc public lazy var modeInfo: TKModeInfo? = template?.modeInfo
  
  public var templateHashCode: Int { template?.hashCode?.intValue ?? 0 }
  
  public var color: TKColor {
    if let color = service?.color {
      return color
    } else if let color = modeInfo?.color {
      return color
    } else if isPublicTransport {
      return TKColor.darkGray // was 143, 139, 138
    } else {
      return TKColor.lightGray // was 214, 214, 214
    }
    
  }
  
  /// A singe line instruction which is used on the map screen.
  @objc public var singleLineInstruction: String? {
    if let instruction = _singleLineInstruction { return instruction }
    
    let (newString, isTimeDependent) = buildSingleLineInstruction(includingTime: true, includingPlatform: false)
    if isTimeDependent {
      // Don't cache, just return, as instructions are dynamic
      return newString
    } else {
      _singleLineInstruction = newString
      return newString
    }
  }
  private var _singleLineInstruction: Optional<String?> = nil


  public var singleLineInstructionWithoutTime: String? {
    if let instruction = _singleLineInstructionWithoutTime { return instruction }
    
    let (newString, isTimeDependent) = buildSingleLineInstruction(includingTime: false, includingPlatform: false)
    if isTimeDependent {
      // Don't cache, just return, as instructions are dynamic
      return newString
    } else {
      _singleLineInstructionWithoutTime = newString
      return newString
    }
  }
  private var _singleLineInstructionWithoutTime: Optional<String?> = nil

  @objc public var notes: String? {
    if let notes = _notes { return notes }
    guard let rawString = template?.notesRaw, !rawString.isEmpty else { return nil }
    
    let (newNotes, isTimeDependent) = fillTemplates(input: rawString, inTitle: false, includingTime: true, includingPlatform: true)
    if isTimeDependent {
      return newNotes
    } else {
      _notes = newNotes
      return newNotes
    }
  }
  private var _notes: Optional<String?> = nil
  
  public var notesWithoutPlatforms: String? {
    if let notesWithoutPlatforms = _notesWithoutPlatforms { return notesWithoutPlatforms }
    guard let rawString = template?.notesRaw, !rawString.isEmpty else { return nil }
    
    let (newNotes, isTimeDependent) = fillTemplates(input: rawString, inTitle: false, includingTime: false, includingPlatform: false)
    if isTimeDependent {
      return newNotes
    } else {
      _notesWithoutPlatforms = newNotes
      return newNotes
    }
  }
  private var _notesWithoutPlatforms: Optional<String?> = nil
  
  /// All alerts for this segment
  @objc public lazy var alerts: [Alert] = {
    guard
      let reference = reference,
      let hashCodes = reference.alertHashCodes,
      let context = reference.managedObjectContext,
      let start = start?.coordinate
    else { return [] }
    
    return hashCodes
      .compactMap { Alert.fetch(hashCode: $0, in: context) }
      .sortedByDistance(from: start)
  }()
  
  public lazy var turnByTurnMode: TKTurnByTurnMode? = template?.turnByTurnMode
  
  public lazy var type: TKSegmentType? = template?.segmentType.flatMap { TKSegmentType(rawValue: $0.intValue) }
  
  @objc public var title: String? {
    get { singleLineInstruction }
    set { /* just for KVO */ }
  }
  
  public var titleWithoutTime: String? { singleLineInstructionWithoutTime }
  

  // MARK: - Inferred properties: Simple
  
  @objc public var isContinuation: Bool { template?.isContinuation ?? false }
  @objc public var isWalking: Bool { template?.isWalking ?? false }
  @objc public var isWheelchair: Bool { template?.isWheelchair ?? false }
  @objc public var isCycling: Bool { template?.isCycling ?? false }
  @objc public var isDriving: Bool { template?.isDriving ?? false }
  @objc public var isFlight: Bool { template?.isFlight ?? false }
  @objc public var hasCarParks: Bool { template?.hasCarParks ?? false }
  @objc public var isPlane: Bool { TKTransportModes.modeIdentifierIsFlight(modeIdentifier ?? "") }
  @objc public var isPublicTransport: Bool { template?.isPublicTransport ?? false }
  @objc public var isSelfNavigating: Bool { template?.isSelfNavigating ?? false }
  @objc public var isAffectedByTraffic: Bool { template?.isAffectedByTraffic ?? false }
  @objc public var isSharedVehicle: Bool { template?.isSharedVehicle ?? false }
  @objc public var isStationary: Bool { order != .regular || template?.isStationary ?? true }

  @objc public var durationWithoutTraffic: TimeInterval { template?.durationWithoutTraffic?.doubleValue ?? 0 }

  @objc public var distanceInMetres: NSNumber? { template?.metres }
  @objc public var distanceInMetresFriendly: NSNumber? { template?.metresFriendly }
  @objc public var distanceInMetresUnfriendly: NSNumber? { template?.metresUnfriendly }
  @objc public var distanceInMetresDismount: NSNumber? { template?.metresDismount }

  @objc public var _rawAction: String? { template?.action }

  public var bearing: NSNumber? { template?.bearing }
  public lazy var mapTiles: TKMapTiles? = template?.mapTiles
  
  // MARK: - Inferred properties: Shapes and visits
  
  @objc public lazy var shapes: [Shape] = {
    let unsorted = (template?.shapes as? Set<Shape>) ?? []
    return unsorted.sorted { $0.index < $1.index }
  }()
  
  /// Dictionary of stop code to bool of which stops along a service this segment is travelling along.
  private var segmentVisits: [String: Bool] {
    if let existing = _segmentVisits { return existing }
    _segmentVisits = buildSegmentVisits()
    return _segmentVisits ?? [:]
  }
  private var _segmentVisits: [String: Bool]? = nil
  
  @objc(usesVisit:)
  public func uses(_ visit: StopVisits) -> Bool {
    guard let service = self.service else { return false }
    
    // be optimistic, if we haven't yet loaded the details as we shouldn't
    // have any un-travelled bits then
    guard service.hasServiceData else { return true }
    
    let visitInfo = segmentVisits[visit.stop.stopCode]
    return visitInfo ?? false
  }
  
  /// Checks if one of the visited `StopVisits` objects matches the provided predicate
  /// - Parameter predicate: Will be called for each visited
  /// - Returns: `true` if the predicate returned `true` for any; `false` if it returned `false` for all, `nil` if visits have not been downloaded yet
  public func usesVisit(where predicate: (StopVisits) -> Bool) -> Bool? {
    guard isPublicTransport else { return false }
    
    guard let sorted = service?.sortedVisits else { return nil }
    
    let visits = segmentVisits
    let visited = sorted.filter { visits[$0.stop.stopCode] == true }
    for visit in visited {
      if predicate(visit) {
        return true
      }
    }
    return false
  }
  
  public func shouldShow(_ visit: StopVisits) -> Bool {
    // commented out the following as it looks a bit
    // weird if when we have bus => walk => bus and
    // only the first bus => walk gets a dot
    //  if ([TKLocationHelper coordinate:[visit coordinate]
    //                            isNear:[self coordinate]]) {
    //    return NO; // don't show the visit where we get on
    //  }
    if visit is DLSEntry {
      return false // These are represented by segments already *and*
                   // they get routinely nuked, so adding them is crashy.
    } else if let visits = _segmentVisits {
      return visits[visit.stop.stopCode] != nil
    } else {
      return true // be optimistic while we haven't loaded the details yet
    }
  }
  
  /// Checks if the provided visit matches this segment. This is not just for where the visit is used by this segment, but also for the parts before and after. This call deals with continuations and if the visit is part of a continuation, the visit is still considered to match this segment.
  /// - Parameter visit: The visit to match to this segment.
  /// - Returns: If the provided visit is matching this segment.
  public func matches(_ visit: StopVisits) -> Bool {
    var segment: TKSegment? = self
    let serviceCodeToMatch = visit.service.code
    while segment != nil {
      if serviceCodeToMatch == segment?.service?.code {
        return true
      }
      segment = segment?.next
      guard let isContinuation = segment?.isContinuation, isContinuation else { return false }
    }
    return false
  }
  
  /// Checks if segment's shape pass near a coordinate
  /// - Parameter coordinate: A coordinate
  /// - Parameter maximumMeters: Maximum distance to return `true`
  /// - Returns: `true` if any of the shapes of this segment pass near the provided coordinate.
  public func passesNear(_ coordinate: CLLocationCoordinate2D, maximumMeters: CLLocationDistance = 100) -> Bool {
    let needle = MKMapPoint(coordinate)
    return shapes
      .compactMap { TKRoutePolyline(route: $0) }
      .contains {
        $0.closestPoint(to: needle).distance < maximumMeters
      }
  }
  

  // MARK: - Inferred properties: Real-time
  
  @objc public var timesAreRealTime: Bool { reference?.timesAreRealTime ?? false }

  @objc public var realTimeVehicle: Vehicle? { service?.vehicle ?? reference?.realTimeVehicle }
  
  @objc public var realTimeAlternativeVehicles: [Vehicle] {
    reference?.realTimeVehicleAlternatives.flatMap(Array.init)
      ?? [] // Not showing alternatives for public transport
  }
  
  @objc public var isImpossible: Bool {
    guard order == .regular else { return false }
    if duration(includingContinuation: false) < 0 { return true }
    
    if let next = self.next {
      let margin: TimeInterval = 60
      return next.departureTime.addingTimeInterval(margin) < arrivalTime
    } else {
      return false
    }
  }
  

  // MARK: - Inferred properties: Public transport
  
  @objc public var service: Service? { reference?.service }
  @objc public var frequency: NSNumber? { service?.frequency }
  @objc public var isCanceled: Bool { service?.isCanceled ?? false }
  @objc public var scheduledServiceNumber: String? { service?.number }
  @objc public var scheduledServiceCode: String? { service?.code }
  @objc public lazy var scheduledStartStopCode: String? = template?.scheduledStartStopCode
  @objc public lazy var scheduledEndStopCode: String? = template?.scheduledEndStopCode
  @objc public lazy var scheduledStartPlatform: String? = reference?.departurePlatform
  @objc public lazy var scheduledEndPlatform: String? = reference?.arrivalPlatform
  @objc public lazy var scheduledTimetableStartTime: Date? = reference?.timetableStartTime
  @objc public lazy var scheduledTimetableEndTime: Date? = reference?.timetableEndTime
  @objc public lazy var ticketWebsiteURLString: String? = reference?.ticketWebsiteURLString

  @objc public var embarkation: StopVisits? {
    guard let service = service else { return nil }
    guard service.hasServiceData else { return service.visits?.first }
    return service.sortedVisits.first { visit in
      return self.segmentVisits[visit.stop.stopCode] == true
    }
  }
  
  @objc public var disembarkation: StopVisits? {
    return service?.sortedVisits.reversed().first { visit in
      return self.segmentVisits[visit.stop.stopCode] == true
    }
  }
  
  @objc public var scheduledServiceStops: Int { reference?.serviceStops ?? 0 }
  
  
  // MARK: - Inferred properties: Booking
  
  private lazy var bookingDataCache: (data: BookingData?, hashCode: Int?) = {
    return (data: reference?.bookingData, hashCode: reference.map { Int($0.bookingHashCode) } )
  }()
  
  private var bookingData: BookingData? {
    guard let newHashCode = reference?.bookingHashCode else { return bookingDataCache.data }
    
    if let oldHashCode = bookingDataCache.hashCode, oldHashCode == newHashCode {
      return bookingDataCache.data
    } else {
      bookingDataCache = (data: reference?.bookingData, hashCode: Int(newHashCode))
      return bookingDataCache.data
    }
  }

  @objc public var bookingTitle: String? { bookingData?.title }
  public var bookingAccessibilityLabel: String? { bookingData?.accessibilityLabel ?? bookingData?.title }
  public var bookingInternalURL: URL? { bookingData?.url }
  public var bookingVirtualURL: URL? { bookingData?.virtualBookingUrl }
  public var bookingQuickInternalURL: URL? { bookingData?.quickBookingsUrl }
  public var bookingExternalActions: [String]? { bookingData?.externalActions }
  public var bookingConfirmation: TKBooking.Confirmation? { bookingData?.confirmation }
  
  // MARK: - Inferred properties: Shared vehicles
  
  public lazy var sharedVehicle: TKAPI.SharedVehicleInfo? = reference?.sharedVehicle
}

extension TKSegment: MKAnnotation {
  @objc public var subtitle: String? { primaryLocationString }
  @objc public var coordinate: CLLocationCoordinate2D { start?.coordinate ?? .invalid }
}

// MARK: - Helper methods

extension Array where Element == Alert {
  fileprivate func sortedByDistance(from: CLLocationCoordinate2D) -> [Alert] {
    tk_filterDuplicates { $0.hashCode == $1.hashCode }
      .sorted {
        if let first = $0.location?.coordinate.distance(from: from), let second = $1.location?.coordinate.distance(from: from) {
          return first < second
        } else {
          // If at least one doesn't have a location prefer the one which does not have one.
          return $0.location == nil
        }
      }
  }
}

extension TKSegment {
  
  @objc(durationIncludingContinuation:)
  public func duration(includingContinuation: Bool) -> TimeInterval {
    let segment = includingContinuation ? finalSegmentIncludingContinuation() : self
    return segment.arrivalTime.timeIntervalSince(departureTime)
  }
  
  @objc
  public func finalSegmentIncludingContinuation() -> TKSegment {
    var segment: TKSegment? = self
    var next = segment?.next
    while next != nil && next!.isContinuation {
      segment = next
      next = segment?.next
    }
    return segment ?? self
  }
  
  @objc
  public func originalSegmentIncludingContinuation() -> TKSegment {
    var segment: TKSegment? = self
    var previous = segment?.previous
    while previous != nil && previous!.isContinuation {
      segment = previous
      previous = segment?.previous
    }
    return segment ?? self
  }
}

extension TKSegment {
  
  public var index: Int {
    reference.map { Int($0.index) } ?? -1
  }
  
  @objc
  public func triggerRealTimeKVO() {
    let time = self.departureTime
    self.departureTime = time

    // Also Title?! We used to do that via ObjC
  }
  
  @objc
  public var timeZone: TimeZone {
    guard let coordinate = start?.coordinate else { return .current }
    return TKRegionManager.shared.timeZone(for: coordinate) ?? .current
  }
  
  /// Validates the segment, to make sure it's in a consistent state.
  /// If it's in an inconsistent state, many things can go wrong. You might
  /// want to add calls to this method to assertions and precondition checks.
  @objc public func validate() -> Bool {
    // Segments need a trip
    guard let trip = trip else { return false }
    
    // A segment should be in its trip's segments
    guard let _ = trip.segments.firstIndex(of: self) else { return false }
    
    // Passed all checks
    return true
  }
  
  
  /// Test if this segment has at least the specific length.
  ///
  /// - note: public transport will always return `true` to this.
  @objc public func hasVisibility(_ type: TKTripSegmentVisibility) -> Bool {
    switch self.order {
    case .start: return type == .inDetails
    case .regular:
      let rawVisibility = self.template?.visibility?.intValue ?? 0
      return rawVisibility >= type.rawValue
    case .end: return type != .inSummary
    }
  }
  
  @objc public func matchesQuery() -> Bool {
    switch order {
    case .start:
      guard
        let queryFrom = trip?.request.fromLocation.coordinate,
        let start = start?.coordinate,
        let distance = start.distance(from: queryFrom)
        else { return true }
      return distance < 250
      
    case .end:
      guard
        let queryTo = trip?.request.toLocation.coordinate,
        let end = end?.coordinate,
        let distance = end.distance(from: queryTo)
        else { return true }
      return distance < 250

    case .regular:
      return true
    }
  }
  
  
}

// MARK: - Path info

extension TKSegment {
  
  public var canShowPathFriendliness: Bool {
    guard let totalMeters = template?.metresFriendly?.doubleValue else { return false }
    return totalMeters > 0
  }
  
}

// MARK: - Vehicles

extension TKSegment {
  
  @objc public var usesVehicle: Bool {
    if template?.isSharedVehicle == true {
      return true
    } else if reference?.vehicleUUID != nil {
      return true
    } else {
      return false
    }
  }
  
  /// The private vehicle type used by this segment (if any)
  @objc public var privateVehicleType: TKVehicleType {
    guard let identifier = modeIdentifier else { return .none }
    
    switch identifier {
    case TKTransportModeIdentifierCar: return .car
    case TKTransportModeIdentifierBicycle: return .bicycle
    case TKTransportModeIdentifierMotorbike: return .motorbike
    default: return .none
    }
  }
  
  /// - Parameter vehicle: Vehicle to assign to this segment. Only takes affect if its of a compatible type.
  public func assign(_ vehicle: TKVehicular?) {
    guard privateVehicleType == vehicle?.vehicleType() else { return }
    
    reference?.assign(vehicle)
  }
  
}


// MARK: - UIActivityItemSource

#if os(iOS)

  extension TKSegment: UIActivityItemSource {
  
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
      
      guard order == .end else { return nil }
      let format = NSLocalizedString("I'll arrive at %@ at %@", tableName: "TripKit", bundle: .tripKit, comment: "First '%@' will be replaced with destination location, second with arrival at that location. (old key: MessageArrivalTime)")
      return String(format: format,
                    trip.request.toLocation.title ?? "",
                    TKStyleManager.timeString(arrivalTime, for: timeZone)
      )
      
    }
    
  }
  
#endif
