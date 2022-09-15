//
//  Loc+TripKit.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/11/16.
//
//

import Foundation

extension Loc {
  
  @objc public static var Trip: String {
    return NSLocalizedString("Trip", tableName: "TripKit", bundle: .tripKit, comment: "Title for a trip")
  }

  public static var OpeningHours: String {
    return NSLocalizedString("Opening Hours", tableName: "TripKit", bundle: .tripKit, comment: "Title for opening hours")
  }
  
  public static var PublicHoliday: String {
    return NSLocalizedString("Public holiday", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static var ShowTimetable: String {
    return NSLocalizedString("Show timetable", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  // MARK: - Vehicles and transport modes
  
  public static var Vehicles: String {
    return NSLocalizedString("Vehicles", tableName: "TripKit", bundle: .tripKit, comment: "Title for showing the number of available vehicles (e.g., scooters, cars or bikes)")
  }

  public static var Vehicle: String {
    return NSLocalizedString("Vehicle", tableName: "TripKit", bundle: .tripKit, comment: "Title for a vehicle of unspecified type")
  }

  @objc
  public static var VehicleTypeBicycle: String {
    return NSLocalizedString("Bicycle", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: Bicycle")
  }
  
  public static var VehicleTypeEBike: String {
    return NSLocalizedString("E-Bike", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: E-Bike")
  }
  
  @objc
  public static var VehicleTypeCar: String {
    return NSLocalizedString("Car", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: Car")
  }
  
  public static var VehicleTypeKickScooter: String {
    return NSLocalizedString("Kick Scooter", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: Kick Scooter")
  }
  
  public static var VehicleTypeMotoScooter: String {
    return NSLocalizedString("Moto Scooter", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: Moto Scooter")
  }

  @objc
  public static var VehicleTypeMotorbike: String {
    return NSLocalizedString("Motorbike", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: Motorbike")
  }

  @objc
  public static var VehicleTypeSUV: String {
    return NSLocalizedString("SUV", tableName: "TripKit", bundle: .tripKit, comment: "Text for vehicle of type: SUV")
  }

  
  // MARK: - Linking to TSP
  
  @objc public static var Disconnect: String {
    return NSLocalizedString("Disconnect", tableName: "TripKit", bundle: .tripKit, comment: "To disconnect/unlink from a service provider, e.g., Uber")
  }
  
  @objc public static var Setup: String {
    return NSLocalizedString("Setup", tableName: "TripKit", bundle: .tripKit, comment: "Set up to connect/link to a service provider, e.g., Uber")
  }
  
  
  // MARK: - Accessibility
  
  public static var FriendlyPath: String {
    return NSLocalizedString("Friendly", tableName: "TripKit", bundle: .tripKit, comment: "Indicating a path is wheelchair/cycyling friendly")
  }
  
  public static var UnfriendlyPath: String {
    return NSLocalizedString("Unfriendly", tableName: "TripKit", bundle: .tripKit, comment: "Indicating a path is wheelchair/cycyling unfriendly")
  }
  
  public static var Dismount: String {
    return NSLocalizedString("Dismount", tableName: "TripKit", bundle: .tripKit, comment: "Indicating a path requires you to dismount and push your bicycle")
  }
  
  public static var Unknown: String {
    return NSLocalizedString("Unknown", tableName: "TripKit", bundle: .tripKit, comment: "Indicator for something unknown/unspecified")
  }
  
  
  // MARK: - Permission manager
  
  public static var ContactsAuthorizationAlertText: String {
    return NSLocalizedString("You previously denied this app access to your contacts. Please go to the Settings app > Privacy > Contacts and authorise this app to use this feature.", tableName: "Shared", bundle: .tripKit, comment: "Contacts authorisation needed text")
  }
  
  public static func PersonsHome(name: String) -> String {
    let format = NSLocalizedString("%@'s Home", tableName: "Shared", bundle: .tripKit, comment: "'%@' will be replaced with the person's name")
    return String(format: format, name)
  }

  public static func PersonsWork(name: String) -> String {
    let format = NSLocalizedString("%@'s Work", tableName: "Shared", bundle: .tripKit, comment: "'%@' will be replaced with the person's name")
    return String(format: format, name)
  }

  public static func PersonsPlace(name: String) -> String {
    let format = NSLocalizedString("%@'s", tableName: "Shared", bundle: .tripKit, comment: "'%@' will be replaced with the person's name. Name for a person's place if it's unclear if it's home, work or something else.")
    return String(format: format, name)
  }

  
  // MARK: - Cards
  
  @objc public static var Dismiss: String {
    return NSLocalizedString("Dismiss", tableName: "TripKit", bundle: .tripKit, comment: "Button to dismiss something, e.g., an error or action action sheet")
  }

  public static var LeaveNow: String {
    return NSLocalizedString("Leave now", tableName: "TripKit", bundle: .tripKit, comment: "Leave ASAP/now option")
  }

  @objc public static var LeaveAt: String {
    return NSLocalizedString("Leave at", tableName: "TripKit", bundle: .tripKit, comment: "Leave after button")
  }
  
  @objc public static var ArriveBy: String {
    return NSLocalizedString("Arrive by", tableName: "TripKit", bundle: .tripKit, comment: "Arrive before button")
  }
  
  @objc public static var Transport: String {
    return NSLocalizedString("Transport", tableName: "TripKit", bundle: .tripKit, comment: "Title for button to access transport modes")
  }
  
  
  // MARK: - Format

  @objc(Departs:capitalize:)
  public static func Departs(atTime time: String, capitalize: Bool = false) -> String {
    let format = NSLocalizedString("departs %@", tableName: "Shared", bundle: .tripKit, comment: "Estimated time of departure; parameter is time, e.g., 'departs 15:30'")
    return String(format: capitalize ? format.localizedCapitalized : format, time)
  }
  
  @objc(Arrives:capitalize:)
  public static func Arrives(atTime time: String, capitalize: Bool = false) -> String {
    let format = NSLocalizedString("arrives %@", tableName: "Shared", bundle: .tripKit, comment: "Estimated time of arrival; parameter is time, e.g., 'arrives 15:30'")
    return String(format: capitalize ? format.localizedCapitalized : format, time)
  }
  
  @objc(FromLocation:)
  public static func From(location from: String) -> String {
    let format = NSLocalizedString("From %@", tableName: "TripKit", bundle: .tripKit, comment: "Departure location. (old key: PrimaryLocationStart)")
    return String(format: format, from)
  }

  @objc(ToLocation:)
  public static func To(location to: String) -> String {
    let format = NSLocalizedString("To %@", tableName: "TripKit", bundle: .tripKit, comment: "Destination location. For trip titles, e.g., 'To work'. (old key: PrimaryLocationEnd)")
    return String(format: format, to)
  }

  @objc(FromTime:toTime:)
  public static func fromTime(_ from: String, toTime to: String) -> String {
    #if os(iOS) || os(tvOS)
    switch UIView.userInterfaceLayoutDirection(for: .unspecified) {
    case .leftToRight:
      return String(format: "%@ → %@", from, to)
    case .rightToLeft:
      return String(format: "%@ ← %@", to, from)
    @unknown default:
      assertionFailure("Unexpected case encountered")
      return String(format: "%@ → %@", from, to)
    }
    #else
    return String(format: "%@ → %@", from, to)
    #endif
  }
  
  @objc(Stops:)
  public static func Stops(_ count: Int) -> String {
    switch count {
    case 0: return ""
      
    case 1: return NSLocalizedString("1 stop", tableName: "TripKit", bundle: .tripKit, comment: "Number of stops before you get off a stop, if there's just 1 stop.")
      
    default:
      let format = NSLocalizedString("%@ stops", tableName: "TripKit", bundle: .tripKit, comment: "Number of stops before you get off a vehicle, if there are 2 stops or more, e.g., '10 stops'. (old key: Stops)")
      return String(format: format, NSNumber(value: count))
    }
  }
  
  public static func UpdatedAgo(duration: String) -> String {
    let format = NSLocalizedString("Updated %@ ago", tableName: "TripKit", bundle: .tripKit, comment: "Vehicle updated. (old key: VehicleUpdated)")
    return String(format: format, duration)
  }
  
}

// MARK: - Segment instructions

extension Loc {
  
  public static var Direction: String {
    return NSLocalizedString("Direction", tableName: "TripKit", bundle: .tripKit, comment: "Destination of the bus")
  }
  
  public static func SomethingAt(time: String) -> String {
    let format = NSLocalizedString("at %@", tableName: "TripKit", bundle: .tripKit, comment: "Time of the bus departure.")
    return String(format: format, time)
  }
  
  public static func SomethingFor(duration: String) -> String {
    let format = NSLocalizedString("for %@", tableName: "TripKit", bundle: .tripKit, comment: "Text indiction for how long a segment might take, where '%@' will be replaced with a duration. E.g., the instruction 'Take bus' might have this next to it as 'for 10 minutes'.")
    return String(format: format, duration)
  }
  
  public static func DurationWithoutTraffic( _ duration: String) -> String {
    let format = NSLocalizedString("%@ w/o traffic", tableName: "TripKit", bundle: .tripKit, comment: "Duration without traffic")
    return String(format: format, duration)
  }
  
  public static func LeaveFromLocation(_ name: String? = nil, at time: String? = nil) -> String {
    if let name = name, !name.isEmpty, let time = time, !time.isEmpty {
      let format = NSLocalizedString("Leave %@ at %@", tableName: "TripKit", bundle: .tripKit, comment: "The first '%@' will be replaced with the place of departure, the second with the departure time. (old key: LeaveLocationTime)")
      return String(format: format, name, time)
      
    } else if let name = name, !name.isEmpty {
      let format = NSLocalizedString("Leave %@", tableName: "TripKit", bundle: .tripKit, comment: "The place of departure. (old key: LeaveLocation)")
      return String(format: format, name)

    } else if let time = time, !time.isEmpty {
      let format = NSLocalizedString("Leave at %@", tableName: "TripKit", bundle: .tripKit, comment: "Departure time. (old key: LeaveTime)")
      return String(format: format, time)

    } else {
      return NSLocalizedString("Leave", tableName: "TripKit", bundle: .tripKit, comment: "Single line instruction to leave")
    }
  }

  public static func LeaveNearLocation(_ name: String?) -> String {
    guard let name = name else { return LeaveFromLocation() }
    
    let format = NSLocalizedString("Depart near %@", tableName: "TripKit", bundle: .tripKit, comment: "Used when the trip does not start at the requested location, but nearby. The '%@' will be replaced with requested departure location.")
    return String(format: format, name)
  }
  
  public static func ArriveAtLocation(_ name: String? = nil, at time: String? = nil) -> String {
    if let name = name, !name.isEmpty, let time = time, !time.isEmpty {
      let format = NSLocalizedString("Arrive %@ at %@", tableName: "TripKit", bundle: .tripKit, comment: "The first '%@' will be replaced with the place of arrival, the second with the arrival time. (old key: ArrivalLocationTime)")
      return String(format: format, name, time)
      
    } else if let name = name, !name.isEmpty {
      let format = NSLocalizedString("Arrive %@", tableName: "TripKit", bundle: .tripKit, comment: "The place of arrival.")
      return String(format: format, name)

    } else if let time = time, !time.isEmpty {
      let format = NSLocalizedString("Arrive at %@", tableName: "TripKit", bundle: .tripKit, comment: "Arrival time.")
      return String(format: format, time)

    } else {
      return NSLocalizedString("Arrive", tableName: "TripKit", bundle: .tripKit, comment: "Single line instruction to arrive")
    }
  }

  public static func ArriveNearLocation(_ name: String?) -> String {
    guard let name = name else { return ArriveAtLocation() }
    
    let format = NSLocalizedString("Arrive near %@", tableName: "TripKit", bundle: .tripKit, comment: "Used when the trip does not end at the requested location, but nearby. The '%@' will be replaced with requested destination location.")
    return String(format: format, name)
  }
  
  
  
}

// MARK: - Alerts

extension Loc {
  
  public static var Alerts: String {
    return NSLocalizedString("Alerts", tableName: "TripKit", bundle: .tripKit, comment: "")
  }

  public static var WeWillKeepYouUpdated: String {
    return NSLocalizedString("We'll keep you updated with the latest transit alerts here", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static func InTheMeantimeKeepExploring(appName: String) -> String {
    let format = NSLocalizedString("In the meantime, let's keep exploring %@ and enjoy your trips", tableName: "TripKit", bundle: .tripKit, comment: "%@ is replaced with app name")
    return String(format: format, appName)
  }
  
  public static func Alerts(_ count: Int) -> String {
    if count == 1 {
      return NSLocalizedString("1 alert", tableName: "TripKit", bundle: .tripKit, comment: "Number of alerts, in this case, there is just one")
    }
    
    let format = NSLocalizedString("%@ alerts", tableName: "TripKit", bundle: .tripKit, comment: "Number of alerts, in this case, there are multiple (plural)")
    return String(format: format, NSNumber(value: count))
  }
  
  @objc
  public static var RoutingBetweenTheseLocationsIsNotYetSupported: String {
    return NSLocalizedString("Routing between these locations is not yet supported.", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
}

// MARK: - Helpers

extension Bundle {
  
  @objc public static let tripKit: Bundle = TripKit.bundle
  
}

