//
//  TKImage+TripKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 12.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension TKImage {
  
  @objc public static let iconSearchTimetable = named("icon-search-timetable")
  @objc public static let backgroundNavSecondary = named("bg-nav-secondary")

  @objc public static let iconPin = named("icon-pin")
  
  // MARK: Modes
  
  public static let iconModeAeroplane = named("icon-mode-aeroplane")
  public static let iconModeAutoRickshaw = named("icon-mode-auto-rickshaw")
  public static let iconModeBicycle = named("icon-mode-bicycle")
  public static let iconModeBicycleElectric = named("icon-mode-bicycle-electric")
  public static let iconModeBicycleFolding = named("icon-mode-folding-bike")
  public static let iconModeBus = named("icon-mode-bus")
  public static let iconModeCablecar = named("icon-mode-cablecar")
  public static let iconModeCar = named("icon-mode-car")
  public static let iconModeCarPool = named("icon-mode-car-pool")
  public static let iconModeCarRideShare = named("icon-mode-car-ride-share")
  public static let iconModeCarShare = named("icon-mode-car-share")
  public static let iconModeCoach = named("icon-mode-coach")
  public static let iconModeFerry = named("icon-mode-ferry")
  public static let iconModeFunicular = named("icon-mode-funicular")
  public static let iconModeGondola = named("icon-mode-gondola")
  public static let iconModeHoverboard = named("icon-mode-hoverboard")
  public static let iconModeKickscooter = named("icon-mode-kickscooter")
  public static let iconModeMonorail = named("icon-mode-monorail")
  public static let iconModeMotorbike = named("icon-mode-motorbike")
  public static let iconModeMotoscooter = named("icon-mode-motoscooter")
  public static let iconModeParking = named("icon-mode-parking")
  public static let iconModePublicTransport = named("icon-mode-public-transport")
  public static let iconModeSegway = named("icon-mode-segway")
  public static let iconModeTaxi = named("icon-mode-taxi")
  public static let iconModeTrain = named("icon-mode-train")
  public static let iconModeTrainIntercity = named("icon-mode-train-intercity")
  public static let iconModeTram = named("icon-mode-tram")
  public static let iconModeUnicycle = named("icon-mode-unicycle")
  public static let iconModeWalk = named("icon-mode-walk")
  public static let iconModeWheelchair = named("icon-mode-wheelchair")
  
  // Battery
  
  public static let iconBattery0 = named("icon-battery-0")
  public static let iconBattery25 = named("icon-battery-25")
  public static let iconBattery50 = named("icon-battery-50")
  public static let iconBattery75 = named("icon-battery-75")
  public static let iconBattery100 = named("icon-battery-100")
  public static let iconBattery = named("icon-battery")
}

extension TKImage {
  
  private static func named(_ name: String) -> TKImage {
    
#if canImport(UIKit)
    return TKImage(named: name, in: .tripKit, compatibleWith: nil)!
#elseif os(macOS)
    return TripKit.bundle.image(forResource: name)!
#endif
  }
}
