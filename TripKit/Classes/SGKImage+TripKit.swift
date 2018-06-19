//
//  SGKImage+TripKit.swift
//  TripKit
//
//  Created by Adrian Schönig on 12.04.18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation

extension SGKImage {
  
  @objc public static let iconSearchTimetable = named("icon-search-timetable")

}

extension SGKImage {
  
  private static func named(_ name: String) -> SGKImage {
    
    let bundle = TKTripKit.bundle()
    #if os(iOS) || os(tvOS)
      return SGKImage(named: name, in: TKTripKit.bundle(), compatibleWith: nil)!
    #elseif os(OSX)
      return bundle.image(forResource: NSImage.Name(rawValue: name))!
    #endif
  }
}


