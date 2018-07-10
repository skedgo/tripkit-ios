//
//  TKCrossPlatform.swift
//  TripKit
//
//  Created by Adrian Schoenig on 27/9/16.
//
//

import Foundation

#if os(iOS) || os(tvOS)
  import UIKit
  public typealias TKColor = UIColor
  public typealias TKImage = UIImage
  public typealias TKFont  = UIFont
#elseif os(OSX)
  import Cocoa
  public typealias TKColor = NSColor
  public typealias TKImage = NSImage
  public typealias TKFont  = NSFont
#endif

@available(*, unavailable, renamed: "TKColor")
public typealias SGKColor = TKImage

@available(*, unavailable, renamed: "TKImage")
public typealias SGKImage = TKImage

@available(*, unavailable, renamed: "TKFont")
public typealias SGKFont = TKFont

#if os(iOS) || os(tvOS)
@available(*, unavailable, renamed: "TKAlertController")
public typealias SGAlert = TKAlertController

@available(*, unavailable, renamed: "TKActions")
public typealias SGActions = TKActions
#endif

@available(*, unavailable, renamed: "TKBetaHelper")
public typealias SGKBetaHelper = TKBetaHelper

@available(*, unavailable, renamed: "TKConfig")
public typealias SGKConfig = TKConfig

@available(*, unavailable, renamed: "TKTimeType")
public typealias SGTimeType = TKTimeType

@available(*, unavailable, renamed: "TKGrouping")
public typealias SGKGrouping = TKGrouping

@available(*, unavailable, renamed: "TKStyleManager")
public typealias SGStyleManager = TKStyleManager
