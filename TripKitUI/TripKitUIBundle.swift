//
//  TripKitUIBundle.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23/06/2016.
//
//

import Foundation
import UIKit

extension UIImage {

  @objc public static let backgroundNavSecondary = named("bg-nav-secondary")

  public static let iconCross = named("icon-cross")
  public static let iconPinNeedle = named("pin-needle")

  // Occupancy
  
  static let iconCheckMini = named("icon-check-mini")
  static let iconExclamationmarkMini = named("icon-exclamation-mark-mini")
  static let iconCrossMini = named("icon-cross-mini")
  static let iconWheelchairMini = named("icon-wheelchair-mini")

  // Badges

  public static let badgeCheck = named("check-mark")
  public static let badgeHeart = named("heart-circle")
  public static let badgeLeaf = named("leaf-circle")
  public static let badgeLightning = named("lightning-circle")
  public static let badgeLike = named("like-circle")
  public static let badgeMoney = named("money-circle")

  // Actions

  public static let iconArrowUp = named("arrow-up")
  public static let iconShowPassword = named("icon-show")
  public static let iconHidePassword = named("icon-hide")
  public static let iconShare = named("share")

  public static let iconChevronDown = named("chevron-down")
  public static let iconChevronRight = named("chevron-right")
  public static let iconChevronUp = named("chevron-up")
  public static let iconChevronTimetable = named("timetable-chevron-down")

  // TripBoy
  
  static let iconTripBoyWorker = named("worker")
  static let iconTripBoyHappy = named("tripboy-smile")
  static let iconTripBoySad = named("tripboy-sad")

}

extension UIImage {
  
  private static func named(_ name: String) -> UIImage {
    return UIImage(named: name, in: .tripKitUI, compatibleWith: nil)!
  }
}


/// :nodoc:
public class TripKitUIBundle: NSObject {
  @objc public static func optionalImageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name, in: .tripKitUI, compatibleWith: nil)
  }

  @objc public static func imageNamed(_ name: String) -> UIImage {
    guard let image = optionalImageNamed(name) else {
      preconditionFailure()
    }
    return image
  }
  
  @objc public static func bundle() -> Bundle {
    return Bundle(for: self)
  }
  
}

extension Bundle {
  
  public static let tripKitUI: Bundle = TripKitUIBundle.bundle()
  
}
