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

  public static let iconAlert = named("icon-alert")
  public static let iconCross = named("icon-cross")

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

  public static let iconAlternative = named("alternative")
  public static let iconArrowUp = named("arrow-up")
  public static let iconShowPassword = named("icon-show")
  public static let iconHidePassword = named("icon-hide")
  public static let iconShare = named("share")

  public static let iconChevronDown = named("chevron-down")
  public static let iconChevronRight = named("chevron-right")
  public static let iconChevronUp = named("chevron-up")
  public static let iconChevronTimetable = named("timetable-chevron-down")
  public static let iconChevronLeft = named("icon-chevron-left")

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

class TripKitUIBundle: NSObject {
  static func optionalImageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name, in: .tripKitUI, compatibleWith: nil)
  }

  static func imageNamed(_ name: String) -> UIImage {
    guard let image = optionalImageNamed(name) else {
      preconditionFailure()
    }
    return image
  }
  
  fileprivate static func bundle() -> Bundle {
    return Bundle(for: self)
  }
  
}

extension Bundle {
  
  public static let tripKitUI: Bundle = TripKitUIBundle.bundle()
  
}
