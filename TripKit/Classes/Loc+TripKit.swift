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
  
}

// MARK: - Helpers

extension Bundle {
  
  @objc public static let tripKit: Bundle = TKTripKit.bundle()
  
}

