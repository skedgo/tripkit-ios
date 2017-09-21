//
//  TKSegment.swift
//  TripKit
//
//  Created by Adrian Schoenig on 31/10/16.
//
//

import Foundation

extension TKSegment {
  
  /// Validates the segment, to make sure it's in a consistent state.
  /// If it's in an inconsistent state, many things can go wrong. You might
  /// want to add calls to this method to assertions and precondition checks.
  @objc public func validate() -> Bool {
    // Segments need a trip
    guard let trip = trip else { return false }
    
    // A segment should be in its trip's segments
    guard let _ = trip.segments().index(of: self) else { return false }
    
    // Passed all checks
    return true
  }
  
  
  @objc public func determineRegions() -> [SVKRegion] {
    guard let start = self.start?.coordinate, let end = self.end?.coordinate else { return [] }
    
    return SVKRegionManager.shared.localRegions(start: start, end: end)
  }
  
  
  /// Test if this segment has at least the specific length.
  ///
  /// - note: public transport will always return `true` to this.
  @objc public func hasVisibility(_ type: STKTripSegmentVisibility) -> Bool {
    switch self.order() {
    case .start: return type == .inDetails
    case .regular:
      let rawVisibility = self.template?.visibility.intValue ?? 0
      return rawVisibility >= type.rawValue
    case .end: return type != .inSummary
    }
  }
  
  
  /// Gets the first alert that requires reroute
  @objc public var reroutingAlert: Alert? {
    return alertsWithAction().first { !$0.excludedStops.isEmpty }
  }
  
}

// MARK: - Vehicles

extension TKSegment {
  
  @objc public var usesVehicle: Bool {
    if template?.isSharedVehicle() ?? false {
      return true
    } else if reference?.vehicleUUID != nil {
      return true
    } else {
      return false
    }
  }
  
  /// - Parameter vehicles: List of the user's vehicles
  /// - Returns: The used vehicle (if there are any) in SkedGo API-compatible form
  @objc public func usedVehicle(fromAll vehicles: [STKVehicular]) -> [AnyHashable: Any]? {
    if template?.isSharedVehicle() ?? false {
      return reference?.sharedVehicleData
    }
    
    if let vehicle = reference?.vehicle(fromAllVehicles: vehicles) {
      return STKVehicularHelper.skedGoReferenceDictionary(forVehicle: vehicle)
    } else {
      return nil
    }
  }
  
  
  /// The private vehicle type used by this segment (if any)
  @objc public var privateVehicleType: STKVehicleType {
    guard let identifier = modeIdentifier() else { return .none }
    
    switch identifier {
    case SVKTransportModeIdentifierCar: return .car
    case SVKTransportModeIdentifierBicycle: return .bicycle
    case SVKTransportModeIdentifierMotorbike: return .motorbike
    default: return .none
    }
  }
  
  /// - Parameter vehicle: Vehicle to assign to this segment. Only takes affect if its of a compatible type.
  @objc public func assignVehicle(_ vehicle: STKVehicular?) {
    guard privateVehicleType == vehicle?.vehicleType() else { return }
    
    reference?.setVehicle(vehicle)
  }
  
}


// MARK: - STKDisplayablePoint

extension TKSegment: STKDisplayablePoint {

  public var isDraggable: Bool {
    return false
  }
  
  public var pointClusterIdentifier: String? {
    return nil
  }
  
  public var pointDisplaysImage: Bool {
    return coordinate.isValid && hasVisibility(.onMap)
  }
  
  public var pointImage: SGKImage? {
    switch order() {
    case .start, .end:
      return SGStyleManager.imageNamed("icon-pin")
      
    case .regular:
      return image(for: .listMainMode, allowRealTime: false)
    }
  }
  
  public var pointImageURL: URL? {
    return imageURL(for: .listMainMode)
  }

  fileprivate func image(for iconType: SGStyleModeIconType, allowRealTime: Bool) -> SGKImage? {
    var localImageName = modeInfo()?.localImageName
    
    if trip.showNoVehicleUUIDAsLift && privateVehicleType == .car && reference?.vehicleUUID == nil {
      localImageName = "car-pool"
    }
    guard let imageName = localImageName else { return nil }
    
    let realTime = allowRealTime && timesAreRealTime()
    return TKSegmentHelper.segmentImage(iconType, localImageName: imageName, modeIdentifier: modeIdentifier(), isRealTime: realTime)
  }

  fileprivate func imageURL(for iconType: SGStyleModeIconType) -> URL? {
    var iconFileNamePart: String? = nil
    
    switch iconType {
    case .mapIcon, .listMainMode, .resolutionIndependent:
      iconFileNamePart = modeInfo()?.remoteImageName
      
    case .listMainModeOnDark, .resolutionIndependentOnDark:
      iconFileNamePart = modeInfo()?.remoteDarkImageName
      
    case .vehicle:
      iconFileNamePart = realTimeVehicle()?.icon
      
    case .alert:
      return nil // not supported for segments
    }
    
    if let part = iconFileNamePart {
      return SVKServer.imageURL(forIconFileNamePart: part, of: iconType)
    } else {
      return SVKRegionManager.shared.imageURL(forModeIdentifier: modeIdentifier(), of: iconType)
    }
  }
}


// MARK: - STKDisplayableTimePoint

extension TKSegment: STKDisplayableTimePoint {
  
  public var time: Date {
    get {
      return departureTime
    }
    set {
      self.departureTime = newValue
    }
  }
  
  public var timeZone: TimeZone {
    guard let coordinate = start?.coordinate else { return .current }
    return SVKRegionManager.shared.timeZone(for: coordinate) ?? .current
  }
  
  public var timeIsRealTime: Bool {
    return self.timesAreRealTime()
  }

  public var bearing: NSNumber? {
    return template?.bearing
  }
  
  public var canFlipImage: Bool {
    // only those pointing left or right
    return isSelfNavigating() || self.modeIdentifier() == SVKTransportModeIdentifierAutoRickshaw
  }
  
  public var isTerminal: Bool {
    return order() == .end
  }
  
}


// MARK: - STKTripSegment

extension TKSegment: STKTripSegment {
  
  public var tripSegmentTimeZone: TimeZone? {
    return timeZone
  }
  
  public var tripSegmentModeImage: SGKImage? {
    return image(for: .listMainMode, allowRealTime: false)
  }
  
  public var tripSegmentModeInfo: ModeInfo? {
    return modeInfo()
  }
  
  public var tripSegmentInstruction: String {
    guard let rawString = template?.miniInstruction.instruction else { return "" }
    let mutable = NSMutableString(string: rawString)
    fill(inTemplates: mutable, inTitle: true)
    return mutable as String
  }
  
  public var tripSegmentMainValue: Any {
    if let rawString = template?.miniInstruction.mainValue {
      let mutable = NSMutableString(string: rawString)
      fill(inTemplates: mutable, inTitle: true)
      return mutable as String
    } else {
      return self.departureTime
    }
  }
  
  public var tripSegmentDetail: String? {
    if let rawString = template?.miniInstruction.detail {
      let mutable = NSMutableString(string: rawString)
      fill(inTemplates: mutable, inTitle: true)
      return mutable as String
    } else {
      return nil
    }
  }
  
  public var tripSegmentTimesAreRealTime: Bool {
    return timesAreRealTime()
  }
  
  public var tripSegmentIsWheelchairAccessible: Bool {
    return reference?.isWheelchairAccessible ?? true
  }
  
  public var tripSegmentFixedDepartureTime: Date? {
    if isPublicTransport() {
      if let frequency = frequency()?.intValue, frequency > 0 {
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
  
  public var tripSegmentModeInfoIconType: STKInfoIconType {
    return alerts().first?.infoIconType ?? .none
  }
  
}


// MARK: - UIActivityItemSource

#if os(iOS)

  extension TKSegment: UIActivityItemSource {
  
    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
      return ""
    }
    
    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
      
      guard order() == .end else { return nil }
      let format = NSLocalizedString("I'll arrive at %@ at %@", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "First '%@' will be replaced with destination location, second with arrival at that location. (old key: MessageArrivalTime)")
      return String(format: format,
                    trip.request.toLocation.title ?? "",
                    SGStyleManager.timeString(arrivalTime, for: timeZone)
      )
      
    }
    
  }
  
#endif
