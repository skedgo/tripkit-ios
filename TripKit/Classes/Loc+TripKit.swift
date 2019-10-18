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

  @objc public static var NoPlannedTrips: String {
    return NSLocalizedString("No planned trips", tableName: "TripKit", bundle: .tripKit, comment: "Indicating no trips have been planned within the next 24 hrs")
  }
  
  @objc public static var OpeningHours: String {
    return NSLocalizedString("Opening Hours", tableName: "TripKit", bundle: .tripKit, comment: "Title for opening hours")
  }
  
  @objc public static var PublicHoliday: String {
    return NSLocalizedString("Public holiday", tableName: "TripKit", bundle: .tripKit, comment: "")
  }
  
  public static var Show: String {
    return NSLocalizedString("Show", tableName: "TripKit", bundle: .tripKit, comment: "Title for button that, when tapped, shows something, e.g., a list of alert")
  }
  
  // MARK: - Vehicles and transport modes
  
  public static var Vehicles: String {
    return NSLocalizedString("Vehicles", tableName: "TripKit", bundle: .tripKit, comment: "Title for showing the number of available vehicles (e.g., scooters, cars or bikes)")
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
  
  public static var UnknownPathFriendliness: String {
    return NSLocalizedString("Unknown", tableName: "TripKit", bundle: .tripKit, comment: "Indicating the wheelchair/cycling friendliness of a path is unknown")
  }
  
  
  // MARK: - Permission manager
  
  public static var ContactsAuthorizationAlertText: String {
    return NSLocalizedString("You previously denied this app access to your contacts. Please go to the Settings app > Privacy > Contacts and authorise this app to use this feature.", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Contacts authorisation needed text")
  }
  
  public static func PersonsHome(name: String) -> String {
    let format = NSLocalizedString("%@'s Home", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "'%@' will be replaced with the person's name")
    return String(format: format, name)
  }

  public static func PersonsWork(name: String) -> String {
    let format = NSLocalizedString("%@'s Work", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "'%@' will be replaced with the person's name")
    return String(format: format, name)
  }

  public static func PersonsPlace(name: String) -> String {
    let format = NSLocalizedString("%@'s", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "'%@' will be replaced with the person's name. Name for a person's place if it's unclear if it's home, work or something else.")
    return String(format: format, name)
  }

  
  // MARK: - Cards
  
  @objc public static var Dismiss: String {
    return NSLocalizedString("Dismiss", tableName: "TripKit", bundle: .tripKit, comment: "Button to dismiss something, e.g., an error or action action sheet")
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
    let format = NSLocalizedString("departs %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Estimated time of departure; parameter is time, e.g., 'departs 15:30'")
    return String(format: capitalize ? format.localizedCapitalized : format, time)
  }
  
  @objc(Arrives:capitalize:)
  public static func Arrives(atTime time: String, capitalize: Bool = false) -> String {
    let format = NSLocalizedString("arrives %@", tableName: "Shared", bundle: TKStyleManager.bundle(), comment: "Estimated time of arrival; parameter is time, e.g., 'arrives 15:30'")
    return String(format: capitalize ? format.localizedCapitalized : format, time)
  }
  
  @objc(ArriveAtDate:)
  public static func ArriveAt(date: String) -> String {
    let format = NSLocalizedString("Arrive at %@", tableName: "TripKit", bundle: .tripKit, comment: "'%@' will be replaced with the arrival time. (old key: ArrivalTime)")
    return String(format: format, date)
  }
  
  @objc(FromLocation:)
  public static func From(location from: String) -> String {
    let format = NSLocalizedString("From %@", tableName: "TripKit", bundle: .tripKit, comment: "Departure location. (old key: PrimaryLocationStart)")
    return String(format: format, from)
  }

  public static var FromCurrentLocation: String {
    return NSLocalizedString("From current location", tableName: "TripKit", bundle: .tripKit, comment: "")
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
  
}

// MARK: - Segment instructions

extension Loc {
  
  @objc(LeaveFromLocationNamed:atTime:)
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

  @objc(LeaveNearLocationNamed:)
  public static func LeaveNearLocation(_ name: String?) -> String {
    guard let name = name else { return LeaveFromLocation() }
    
    let format = NSLocalizedString("Depart near %@", tableName: "TripKit", bundle: .tripKit, comment: "Used when the trip does not start at the requested location, but nearby. The '%@' will be replaced with requested departure location.")
    return String(format: format, name)
  }
  
  @objc(ArriveAtLocationNamed:atTime:)
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

  @objc(ArriveNearLocationNamed:)
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

  public static var MoreInfo: String {
    return NSLocalizedString("More info", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title of button to get more details about an alert")
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
  
  @objc public static let tripKit: Bundle = TKTripKit.bundle()
  
}

