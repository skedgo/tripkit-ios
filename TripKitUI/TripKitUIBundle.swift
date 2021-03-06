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
  
  // Occupancy
  
  static let iconCheckMini = named("icon-check-mini")
  static let iconExclamationmarkMini = named("icon-exclamation-mark-mini")
  static let iconCrossMini = named("icon-cross-mini")
  static let iconWheelchairMini = named("icon-wheelchair-mini")

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
