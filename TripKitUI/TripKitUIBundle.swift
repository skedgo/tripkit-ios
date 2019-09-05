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

  // Priorities
  
  public static let iconMoney = named("icon-money")
  public static let iconTime = named("icon-time")
  public static let iconTree = named("icon-tree")
  public static let iconRelax = named("icon-relax")
  public static let iconRun = named("icon-run")
  
  // Actions

  public static let iconArrowUp = named("arrow-up")
  public static let iconShowPassword = named("icon-show")
  public static let iconHidePassword = named("icon-hide")
  public static let iconShare = named("share")

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


public class TripKitUIBundle: NSObject {
  @objc public class func optionalImageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name, in: .tripKitUI, compatibleWith: nil)
  }

  @objc public class func imageNamed(_ name: String) -> UIImage {
    guard let image = optionalImageNamed(name) else {
      preconditionFailure()
    }
    return image
  }
  
  @objc public class func bundle() -> Bundle {
    return Bundle(for: self)
  }
  
}

extension Bundle {
  
  public static let tripKitUI: Bundle = TripKitUIBundle.bundle()
  
}
