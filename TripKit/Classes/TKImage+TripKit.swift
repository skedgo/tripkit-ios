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

  @objc public static let iconPin = named("icon-pin")
  
  // MARK: Modes
  
  public static let iconModeBicycle = named("icon-mode-bicycle")

}

extension TKImage {
  
  private static func named(_ name: String) -> TKImage {
    
    let bundle = TKTripKit.bundle()
    #if os(iOS) || os(tvOS)
      return TKImage(named: name, in: TKTripKit.bundle(), compatibleWith: nil)!
    #elseif os(OSX)
      return bundle.image(forResource: NSImage.Name(rawValue: name))!
    #endif
  }
}


