//
//  TripKitUIBundle.swift
//  TripKit
//
//  Created by Adrian Schoenig on 23/06/2016.
//
//

import Foundation
import UIKit

public class TripKitUIBundle: NSObject {
  @objc public class func optionalImageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name, in: bundle(), compatibleWith: nil)
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
