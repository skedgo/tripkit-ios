//
//  TKCrossPlatform.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

#if canImport(UIKit)
  import UIKit
  public typealias TKColor = UIColor
  public typealias TKImage = UIImage
  public typealias TKFont  = UIFont
#elseif canImport(AppKit)
  import AppKit
  public typealias TKColor = NSColor
  public typealias TKImage = NSImage
  public typealias TKFont  = NSFont
#endif
