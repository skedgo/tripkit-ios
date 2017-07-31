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
  public class func optionalImageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name, in: bundle(), compatibleWith: nil)
  }

  public class func imageNamed(_ name: String) -> UIImage {
    guard let image = optionalImageNamed(name) else {
      preconditionFailure()
    }
    return image
  }
  
  public class func bundle() -> Bundle {
    return Bundle(for: self)
  }
  
}
