//
//  TKSegment.swift
//  TripKit
//
//  Created by Adrian Schoenig on 31/10/16.
//
//

import Foundation

extension TKSegment {
  
  public var index: Int {
    return reference?.index.intValue ?? -1
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
  
  
  @objc public func determineRegions() -> [TKRegion] {
    guard let start = self.start?.coordinate, let end = self.end?.coordinate else { return [] }
    
    return TKRegionManager.shared.localRegions(start: start, end: end)
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
  
  /// Gets the first alert that requires reroute
  @objc public var reroutingAlert: Alert? {
    return alertsWithAction().first { !$0.stopsExcludedFromRouting.isEmpty }
  }
  
  public var turnByTurnMode: TKTurnByTurnMode? {
    return template?.turnByTurnMode
  }
  
  public var type: TKSegmentType? {
    return template?.segmentType.flatMap { TKSegmentType(rawValue: $0.intValue) }
  }
  
}

// MARK: - Public transport

extension TKSegment {
  
  @objc public var scheduledStartStopCode: String? { template?.scheduledStartStopCode }

  @objc public var scheduledEndStopCode: String? { template?.scheduledEndStopCode }

  @objc public var scheduledStartPlatform: String? { reference?.departurePlatform }
  
  @objc public var scheduledEndPlatform: String? { reference?.arrivalPlatform }
  
  public var scheduledTimetableStartTime: Date? { reference?.timetableStartTime }

  public var scheduledTimetableEndTime: Date? { reference?.timetableEndTime }
  
  public var ticketWebsiteURLString: String? { reference?.ticketWebsiteURLString }

  public var embarkation: StopVisits? {
    return service?.sortedVisits.first { visit in
      return self.segmentVisits()[visit.stop.stopCode]?.boolValue == true
    }
  }
  
  public var disembarkation: StopVisits? {
    return service?.sortedVisits.reversed().first { visit in
      return self.segmentVisits()[visit.stop.stopCode]?.boolValue == true
    }
  }
  
  @objc var scheduledServiceStops: Int { reference?.serviceStops ?? 0 }
  
}

// MARK: - Booking

extension TKSegment {

  public var bookingTitle: String? { reference?.bookingData?.title }
  
  public var bookingInternalURL: URL? { reference?.bookingData?.url }
  
  public var bookingQuickInternalURL: URL? { reference?.bookingData?.quickBookingsUrl }
  
  public var bookingExternalActions: [String]? { reference?.bookingData?.externalActions }
  
  public var bookingConfirmation: TKBooking.Confirmation? { reference?.bookingData?.confirmation }

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
  
  /// - Parameter vehicles: List of the user's vehicles
  /// - Returns: The used vehicle (if there are any) in SkedGo API-compatible form
  @objc public func usedVehicle(fromAll vehicles: [TKVehicular]) -> [AnyHashable: Any]? {
    if template?.isSharedVehicle == true {
      return reference?.sharedVehicleData as? [AnyHashable: Any]
    }
    
    if let vehicle = reference?.vehicle(fromAllVehicles: vehicles) {
      return TKVehicularHelper.skedGoReferenceDictionary(forVehicle: vehicle)
    } else {
      return nil
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
  @objc public func assignVehicle(_ vehicle: TKVehicular?) {
    guard privateVehicleType == vehicle?.vehicleType() else { return }
    
    reference?.setVehicle(vehicle)
  }
  
}


// MARK: - Image helpers

extension TKSegment {
  
  fileprivate func image() -> TKImage? {
    var localImageName = modeInfo?.localImageName
    
    if trip.showNoVehicleUUIDAsLift && privateVehicleType == .car && reference?.vehicleUUID == nil {
      localImageName = "car-pool"
    }
    guard let imageName = localImageName else { return nil }
    
    if let specificImage = TKStyleManager.image(forModeImageName: imageName) {
      return specificImage
    
    } else if let modeIdentifier = modeIdentifier {
      let genericImageName = TKTransportModes.modeImageName(forModeIdentifier: modeIdentifier)
      return TKStyleManager.image(forModeImageName: genericImageName)

    } else {
      return nil
    }
  }

  fileprivate func imageURL(for iconType: TKStyleModeIconType) -> URL? {
    if iconType == .vehicle, let icon = realTimeVehicle?.icon {
      return TKServer.imageURL(iconFileNamePart: icon, iconType: iconType)
    } else {
      return modeInfo?.imageURL(type: iconType)
    }
  }
}




// MARK: - TKTripSegment

extension TKSegment: TKTripSegment {
  
  public var tripSegmentTimeZone: TimeZone? {
    return timeZone
  }
  
  public var tripSegmentModeImage: TKImage? {
    return image()
  }
  
  public var tripSegmentModeInfo: TKModeInfo? {
    return modeInfo
  }
  
  public var tripSegmentInstruction: String {
    guard let rawString = template?.miniInstruction?.instruction else { return "" }
    let mutable = NSMutableString(string: rawString)
    fill(inTemplates: mutable, inTitle: true, includingTime: true, includingPlatform: true)
    return mutable as String
  }
  
  public var tripSegmentDetail: String? {
    if let rawString = template?.miniInstruction?.detail {
      let mutable = NSMutableString(string: rawString)
      fill(inTemplates: mutable, inTitle: true, includingTime: true, includingPlatform: true)
      return mutable as String
    } else {
      return nil
    }
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
    let modeAlerts = alerts()
      .filter { $0.isForMode }
      .sorted { $0.alertSeverity.rawValue > $1.alertSeverity.rawValue }

    return modeAlerts.first?.infoIconType ?? .none
  }

  public var tripSegmentSubtitleIconType: TKInfoIconType {
    let nonModeAlerts = alerts()
      .filter { !$0.isForMode }
      .sorted { $0.alertSeverity.rawValue > $1.alertSeverity.rawValue }

    return nonModeAlerts.first?.infoIconType ?? .none
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

// MARK: - UIActivityItemSource

#if os(iOS)

  extension TKSegment: UIActivityItemSource {
  
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
      
      guard order == .end else { return nil }
      let format = NSLocalizedString("I'll arrive at %@ at %@", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "First '%@' will be replaced with destination location, second with arrival at that location. (old key: MessageArrivalTime)")
      return String(format: format,
                    trip.request.toLocation.title ?? "",
                    TKStyleManager.timeString(arrivalTime, for: timeZone)
      )
      
    }
    
  }
  
#endif
