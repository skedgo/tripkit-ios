//
//  SGKCrossPlatform.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

#if os(iOS) || os(tvOS)
  import UIKit
  public typealias SGKColor = UIColor
  public typealias SGKImage = UIImage
  public typealias SGKFont  = UIFont
#elseif os(OSX)
  import Cocoa
  public typealias SGKColor = NSColor
  public typealias SGKImage = NSImage
  public typealias SGKFont  = NSFont
#endif
